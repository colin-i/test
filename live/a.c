
query {
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
}
