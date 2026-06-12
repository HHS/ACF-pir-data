import pytest


class TestHelpers:
    def test_uqid(self, client):
        response = client.post(
            "/helpers/uqid",
            json=[
                {"question_number": "B.18.d-1", "year": 2023},
                {
                    "question_number": "B.18.d-1",
                    "year": 2024,
                },  # Should have same uqid as above
                {"question_number": "A.21.k-1", "year": 2009},
                {"question_number": "B.5-4", "year": 2011},  # Should have no uqid
            ],
        )

        assert (
            set(response.json).difference(
                {
                    "e358fa167d3a9d5872f563ec5cfa07898a7ee186",
                    "6c9f2d2dcd01048e5163e12a1f50cb8e7c926e43",
                }
            )
            == set()
        )


if __name__ == "__main__":
    pytest.main([__file__, "-vv", "-s"])
