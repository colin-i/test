
import requests

class GraphqlClient:
    """Class which represents the interface to make graphQL requests through."""

    def __init__(self, endpoint: str, headers: dict = {}):
        """Insantiate the client."""
        self.endpoint = endpoint
        self.headers = headers

    def execute(
        self,
        query: str
    ):

        result = requests.post(
            self.endpoint,
            json={"query": query},
            headers={**self.headers}
        )

        return result.json()

with open("/home/bc/n/pat", "r") as file:
	client = GraphqlClient(endpoint="https://api.github.com/graphql",headers={"Authorization": "Bearer {}".format(file.read())})

def shifted(a):
	b=a.__str__()
	if a<10:
		return '0'+b
	return b

from datetime import date
import time
from string import Template

def full():
	t=time.time()
	yesterday=date.fromtimestamp(t-(24*3600))
	tomorrow=date.fromtimestamp(t+(24*3600))

	dict = { 'from': yesterday.year.__str__()+"-"+shifted(yesterday.month)+"-"+shifted(yesterday.day),
		'to': tomorrow.year.__str__()+"-"+shifted(tomorrow.month)+"-"+shifted(tomorrow.day) }

	#with .format there are too many {}
	q=Template("""query {
	  viewer {
	    contributionsCollection(from:"${from}T00:00:00Z",to:"${to}T00:00:00Z") {
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
	}""").substitute(**dict)
	#for forks get like at stats and totalCount (can go further exactly as at stats with author compare)

	return client.execute(query=q)
