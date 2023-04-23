
import json
import requests

class GraphqlClient:
    """Class which represents the interface to make graphQL requests through."""

    def __init__(self, endpoint: str, headers: dict = {}):
        """Insantiate the client."""
        self.endpoint = endpoint
        self.headers = headers

    def execute(
        self,
        query: str,
        headers: dict = {}
    ):

        result = requests.post(
            self.endpoint,
            json={"query": query},
            headers={**self.headers, **headers}
        )

        return result.json()

client = GraphqlClient(endpoint="https://api.github.com/graphql")

q="""query {
  viewer {
    contributionsCollection(from:"2023-04-23T00:00:00Z",to:"2023-04-24T00:00:00Z") {
      commitContributionsByRepository{
        repository{
         name
        }
        contributions(first:2){
          edges{
            node{
              occurredAt
              commitCount
            }
          }
         totalCount
        }
      }
    }
  }
}"""
#for forks get like at stats and totalCount (can go further exactly as at stats with author compare)

with open("/home/bc/n/pat", "r") as file:
	data = client.execute(query=q,headers={"Authorization": "Bearer {}".format(file.read())})
	print(json.dumps(data, indent=1))
