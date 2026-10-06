def test_admin_can_list_users(client, admin):
    assert client.get("/admin/users", headers=admin).status_code == 200


def test_customer_cannot_list_users(client, customer):
    assert client.get("/admin/users", headers=customer).status_code == 403
