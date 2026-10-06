def test_carriers_sorted_by_name(client, customer):
    names = [c["name"] for c in client.get("/carriers", headers=customer).json()]
    assert names == sorted(names)


def test_carriers_reject_unknown_sort(client, customer):
    assert client.get("/carriers", params={"sort": "price"}, headers=customer).status_code == 400
