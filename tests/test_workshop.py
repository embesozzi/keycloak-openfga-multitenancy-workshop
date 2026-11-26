"""End-to-end tests of the running multi-tenancy workshop.

1. The extension published the role model, the role assignment and the organization membership to OpenFGA.
2. The tenant routes of APISIX: a user needs the role AND membership of the organization in the URL.

Run: make test
"""
import os
import time

import pytest
import requests

KEYCLOAK = os.getenv("KEYCLOAK_URL", "http://keycloak:8081")
OPENFGA = os.getenv("OPENFGA_URL", "http://openfga:8080")
APISIX = os.getenv("APISIX_URL", "http://apisix:9080")
REALM = "PayPlus"
PASSWORD = "demo1234!"
TEST_CLIENT = "smoke-test"  # created by keycloak/init.sh, testing only


def token(username):
    r = requests.post(
        f"{KEYCLOAK}/realms/{REALM}/protocol/openid-connect/token",
        data={"grant_type": "password", "client_id": TEST_CLIENT, "username": username, "password": PASSWORD},
    )
    r.raise_for_status()
    return r.json()["access_token"]


@pytest.fixture(scope="session")
def admin():
    r = requests.post(
        f"{KEYCLOAK}/realms/master/protocol/openid-connect/token",
        data={"grant_type": "password", "client_id": "admin-cli",
              "username": os.getenv("KEYCLOAK_USER", "admin"), "password": os.getenv("KEYCLOAK_PASSWORD", "password")},
    )
    r.raise_for_status()
    s = requests.Session()
    s.headers["Authorization"] = f"Bearer {r.json()['access_token']}"
    return s


@pytest.fixture(scope="session")
def user_id(admin):
    def get(username):
        r = admin.get(f"{KEYCLOAK}/admin/realms/{REALM}/users", params={"username": username, "exact": "true"})
        r.raise_for_status()
        return r.json()[0]["id"]
    return get


@pytest.fixture(scope="session", autouse=True)
def apisix_up():
    """APISIX starts after the import and takes a few seconds to listen."""
    for _ in range(60):
        try:
            requests.get(f"{APISIX}/api/org-a/transactions", timeout=2)
            return
        except requests.ConnectionError:
            time.sleep(2)
    pytest.fail(f"{APISIX} is not up")


@pytest.fixture(scope="session")
def tuples():
    stores = requests.get(f"{OPENFGA}/stores").json()["stores"]
    store_id = next(s["id"] for s in stores if s["name"] == "keycloak")
    r = requests.post(f"{OPENFGA}/stores/{store_id}/read", json={})
    r.raise_for_status()
    return {(t["key"]["user"], t["key"]["relation"], t["key"]["object"]) for t in r.json()["tuples"]}


@pytest.mark.parametrize("user, relation, obj", [
    ("role:account-manager", "parent", "role:view_transaction_any"),
    ("paula.smith", "assignee", "role:account-manager"),
    ("paula.smith", "member", "organization:org-a"),
])
def test_tuple_published(tuples, user_id, user, relation, obj):
    if not user.startswith("role:"):
        user = f"user:{user_id(user)}"
    assert (user, relation, obj) in tuples


def test_token_has_organization_claim():
    """The portal reads the tenant from the organization claim (organization scope)."""
    r = requests.post(
        f"{KEYCLOAK}/realms/{REALM}/protocol/openid-connect/token",
        data={"grant_type": "password", "client_id": TEST_CLIENT, "username": "paula.smith",
              "password": PASSWORD, "scope": "openid organization"},
    )
    r.raise_for_status()
    userinfo = requests.get(f"{KEYCLOAK}/realms/{REALM}/protocol/openid-connect/userinfo",
                            headers={"Authorization": f"Bearer {r.json()['access_token']}"}).json()
    assert "org-a" in userinfo["organization"]


@pytest.mark.parametrize("org, status", [
    ("org-a", 200),  # member of org-a, with view_transaction_any
    ("org-b", 403),  # not a member of org-b
])
def test_tenant_route(org, status):
    headers = {"Authorization": f"Bearer {token('paula.smith')}"}
    assert requests.get(f"{APISIX}/api/{org}/transactions", headers=headers).status_code == status


def test_no_token_is_denied():
    assert requests.get(f"{APISIX}/api/org-a/transactions").status_code in (401, 403)
