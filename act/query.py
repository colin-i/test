
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

def day(delta):
	stamp=date.fromtimestamp(time.time()-delta)

	dict = {'day': stamp.year.__str__()+"-"+shifted(stamp.month)+"-"+shifted(stamp.day)}

	#with .format there are too many {}
	#"You must provide a `first` or `last`". it gets 1: yesterday one and today one
	#	occurredAt	is always same
	#	totalCount	is commitCount1+...n	n is 1
	#
	q=Template("""query {
	  viewer {
	    contributionsCollection(from:"${day}T00:00:00Z",to:"${day}T23:59:59Z") {
	      commitContributionsByRepository{
	        repository{
	         name
	        }
	        contributions(first:1){
	          edges{
	            node{
	              commitCount
	            }
	          }
	        }
	      }
	    }
	  }
	}""").substitute(**dict)
	#for forks get like at stats and totalCount (can go further exactly as at stats with author compare)

	js=client.execute(query=q)

	return js

def yesterday():
	return day(24*3600)

def today():
	return day(0)
