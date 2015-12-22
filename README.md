## Indexes in MongoDB

Here I'm gonna show a simple hands-on experience creating indexes in MongoDB. There is a good documentation about indexing strategies, please take a look at URL below before running this hands-on:

https://docs.mongodb.org/v3.0/applications/indexes/


Hands-on experience

## Requirements
 - curl
 - mongo

## Step1 - Prepare data


Getting a large data content:

You can get people.json file bundled with project. It has only 9k docs, but for better experience you can import same file many times. This is how to import json files:

```bash
mongoimport --host localhost --port <mongo-port> --db users --collection people --file import/people.json
```

Just FYI, I've made my tests with 500k user docs.


If you wanna get your own data, here is a script to get random user info from https://randomuser.me/api/

```bash
#!/bin/bash

while true; do
   echo " " >> people.json
   curl -s -m 50 https://randomuser.me/api/>> people.json
done
```


Documents from people collection seems like this document below. Each document came from api with an user inside a "results" array. That doesn't fit for us. We would like to have a document as shown below:


From API
```javascript
...
{
    "results": [
        {
            "user": {
                "gender": "male",
                "name": {
                    "title": "mr",
                    "first": "melvin",
                    "last": "lynch"
                },
                "location": {
                    "street": "4095 park avenue",
                    "city": "preston",
                    "state": "warwickshire",
                    "zip": "UH7N 6BA"
                },
                "email": "melvin.lynch@example.com",
                "username": "lazyladybug666",
                "password": "account",
                "salt": "jfna61L5",
                "md5": "a80b2c5d0f8c4f572050c1df977dc495",
                "sha1": "f5c4c265cc75366f57f231f50c2b13235e7f28a6",
                "sha256": "40ff5233082e24772f457760aa43cc4542ce6151da2457ced3d42032ed9fa2f1",
                "registered": 995405546,
                "dob": 498821984,
                "phone": "0111780 172 3122",
                "cell": "0721-229-194",
                "NINO": "RN 55 62 27 M",
                "picture": {
                    "large": "https://randomuser.me/api/portraits/men/40.jpg",
                    "medium": "https://randomuser.me/api/portraits/med/men/40.jpg",
                    "thumbnail": "https://randomuser.me/api/portraits/thumb/men/40.jpg"
                }
            }
        }
    ],
    "nationality": "GB",
    "seed": "159650a5633f92d604",
    "version": "0.7"
}
...
```

Expected
```javascript
...
{
	"_id" : ObjectId("5649eb27e524ee5a08d3d6bc"),
	"nationality" : "GB",
	"gender" : "male",
	"name" : {
		"title" : "mr",
		"first" : "melvin",
		"last" : "lynch"
	},
	"location" : {
		"street" : "4095 park avenue",
		"city" : "preston",
		"state" : "warwickshire",
		"zip" : "UH7N 6BA"
	},
	"email" : "melvin.lynch@example.com",
	"username" : "lazyladybug666",
	"password" : "account",
	"salt" : "jfna61L5",
	"md5" : "a80b2c5d0f8c4f572050c1df977dc495",
	"sha1" : "f5c4c265cc75366f57f231f50c2b13235e7f28a6",
	"sha256" : "40ff5233082e24772f457760aa43cc4542ce6151da2457ced3d42032ed9fa2f1",
	"registered" : 995405546,
	"dob" : 498821984,
	"phone" : "0111780 172 3122",
	"cell" : "0721-229-194",
	"NINO" : "RN 55 62 27 M",
	"picture" : {
		"large" : "https://randomuser.me/api/portraits/men/40.jpg",
		"medium" : "https://randomuser.me/api/portraits/med/men/40.jpg",
		"thumbnail" : "https://randomuser.me/api/portraits/thumb/men/40.jpg"
	}
}
...
```

We are going to change documents using Aggregation Framework sending the result to other collections called folks:
```javascript
db.people.aggregate(
[
  {
    $unwind: "$results"
  },
  {
    $project: {
      nationality: 1,
      gender: "$results.user.gender",
      name: "$results.user.name",
      location: "$results.user.location",
      email: "$results.user.email",
      username: "$results.user.username",
      password: "$results.user.password",
      salt: "$results.user.salt",
      md5: "$results.user.md5",
      sha1: "$results.user.sha1",
      sha256: "$results.user.sha256",
      registered: "$results.user.registered",
      dob: "$results.user.dob",
      phone: "$results.user.phone",
      cell: "$results.user.cell",
      NINO: "$results.user.NINO",
      picture: "$results.user.picture"
    }
  },
  {
    $out: "folks"
  }
])
```

So, we have a new collection called folks!


## Step 2 - Using indexes

### Index types:

 - Simple index
 - Dot notation
 - Object 
 - Compound
 - Multikey indexes
 - Sparse
	- disvantage: cannot use in sort (otherwise COLLSCAN)
	- vantage: lower size index
 - Text


### Index analysis:

Take a look at one document:
```javascript
> use users
> db.folks.findOne()
{
	"_id" : ObjectId("5678a34257651bc11e1c8fed"),
	"nationality" : "GB",
	"gender" : "male",
	"name" : {
		"title" : "mr",
		"first" : "melvin",
		"last" : "lynch"
	},
	"location" : {
		"street" : "4095 park avenue",
		"city" : "preston",
		"state" : "warwickshire",
		"zip" : "UH7N 6BA"
	},
	"email" : "melvin.lynch@example.com",
	"username" : "lazyladybug666",
	"password" : "account",
	"salt" : "jfna61L5",
	"md5" : "a80b2c5d0f8c4f572050c1df977dc495",
	"sha1" : "f5c4c265cc75366f57f231f50c2b13235e7f28a6",
	"sha256" : "40ff5233082e24772f457760aa43cc4542ce6151da2457ced3d42032ed9fa2f1",
	"registered" : 995405546,
	"dob" : 498821984,
	"phone" : "0111780 172 3122",
	"cell" : "0721-229-194",
	"NINO" : "RN 55 62 27 M",
	"picture" : {
		"large" : "https://randomuser.me/api/portraits/men/40.jpg",
		"medium" : "https://randomuser.me/api/portraits/med/men/40.jpg",
		"thumbnail" : "https://randomuser.me/api/portraits/thumb/men/40.jpg"
	}
}
```

#### There is 3 ways to check details about query execution:

> explain() is nice to check winningPlan and rejectedPlans
```javascript
> db.folks.find({"name.first":"melvin"}).explain()
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "users.folks",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"name.first" : {
				"$eq" : "melvin"
			}
		},
		"winningPlan" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"name.first" : {
					"$eq" : "melvin"
				}
			},
			"direction" : "forward"
		},
		"rejectedPlans" : [ ]
	},
	"serverInfo" : {
		"host" : "berro-ubuntu",
		"port" : 27017,
		"version" : "3.0.7",
		"gitVersion" : "6ce7cbe8c6b899552dadd907604559806aa2e9bd"
	},
	"ok" : 1
}
```

> Using explain("executionStats") you can check details on each query step: 
 - nReturned : returned documents in a step
 - executionTimeMillis: execution time in a step
 - totalKeysExamined: number of keys examined in all step
 - totalDocsExamined: number of documents examined in all steps
 - stage "COLLSCAN": it's not using index. That's a potential candidate for index
 - docsExamined: number of documents examined in a step
```javascript
> db.folks.find({"name.first":"melvin"}).explain("executionStats")
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "users.folks",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"name.first" : {
				"$eq" : "melvin"
			}
		},
		"winningPlan" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"name.first" : {
					"$eq" : "melvin"
				}
			},
			"direction" : "forward"
		},
		"rejectedPlans" : [ ]
	},
	"executionStats" : {
		"executionSuccess" : true,
		"nReturned" : 78,
		"executionTimeMillis" : 47,
		"totalKeysExamined" : 0,
		"totalDocsExamined" : 57648,
		"executionStages" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"name.first" : {
					"$eq" : "melvin"
				}
			},
			"nReturned" : 78,
			"executionTimeMillisEstimate" : 40,
			"works" : 57650,
			"advanced" : 78,
			"needTime" : 57571,
			"needFetch" : 0,
			"saveState" : 450,
			"restoreState" : 450,
			"isEOF" : 1,
			"invalidates" : 0,
			"direction" : "forward",
			"docsExamined" : 57648
		}
	},
	"serverInfo" : {
		"host" : "berro-ubuntu",
		"port" : 27017,
		"version" : "3.0.7",
		"gitVersion" : "6ce7cbe8c6b899552dadd907604559806aa2e9bd"
	},
	"ok" : 1
}
```

> explain("allPlansExecution") show all information above
```javascript
> db.folks.find({"name.first":"melvin"}).explain("allPlansExecution")
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "users.folks",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"name.first" : {
				"$eq" : "melvin"
			}
		},
		"winningPlan" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"name.first" : {
					"$eq" : "melvin"
				}
			},
			"direction" : "forward"
		},
		"rejectedPlans" : [ ]
	},
	"executionStats" : {
		"executionSuccess" : true,
		"nReturned" : 78,
		"executionTimeMillis" : 37,
		"totalKeysExamined" : 0,
		"totalDocsExamined" : 57648,
		"executionStages" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"name.first" : {
					"$eq" : "melvin"
				}
			},
			"nReturned" : 78,
			"executionTimeMillisEstimate" : 40,
			"works" : 57650,
			"advanced" : 78,
			"needTime" : 57571,
			"needFetch" : 0,
			"saveState" : 450,
			"restoreState" : 450,
			"isEOF" : 1,
			"invalidates" : 0,
			"direction" : "forward",
			"docsExamined" : 57648
		},
		"allPlansExecution" : [ ]
	},
	"serverInfo" : {
		"host" : "berro-ubuntu",
		"port" : 27017,
		"version" : "3.0.7",
		"gitVersion" : "6ce7cbe8c6b899552dadd907604559806aa2e9bd"
	},
	"ok" : 1
}
```

### Size of indexes
```javascript
> db.folks.stats()
{
	"ns" : "users.folks",
	"count" : 57648,
	"size" : 58109184,
	"avgObjSize" : 1008,
	"numExtents" : 10,
	"storageSize" : 86310912,
	"lastExtentSize" : 27869184,
	"paddingFactor" : 1,
	"paddingFactorNote" : "paddingFactor is unused and unmaintained in 3.0. It remains hard coded to 1.0 for compatibility only.",
	"userFlags" : 1,
	"capped" : false,
	"nindexes" : 2,
	"totalIndexSize" : 3442096,
	"indexSizes" : {
		"_id_" : 1872304,
		"location.city_1" : 1569792
	},
	"ok" : 1
}
```


### Simple index 

Try this without index and check that there is a stage "COLLSCAN":
```javascript
> db.folks.find({"location.city":"preston"}).explain("executionStats")
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "users.folks",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"location.city" : {
				"$eq" : "preston"
			}
		},
		"winningPlan" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"location.city" : {
					"$eq" : "preston"
				}
			},
			"direction" : "forward"
		},
		"rejectedPlans" : [ ]
	},
	"executionStats" : {
		"executionSuccess" : true,
		"nReturned" : 60,
		"executionTimeMillis" : 39,
		"totalKeysExamined" : 0,
		"totalDocsExamined" : 57648,
		"executionStages" : {
			"stage" : "COLLSCAN",
			"filter" : {
				"location.city" : {
					"$eq" : "preston"
				}
			},
			"nReturned" : 60,
			"executionTimeMillisEstimate" : 30,
			"works" : 57650,
			"advanced" : 60,
			"needTime" : 57589,
			"needFetch" : 0,
			"saveState" : 450,
			"restoreState" : 450,
			"isEOF" : 1,
			"invalidates" : 0,
			"direction" : "forward",
			"docsExamined" : 57648
		}
	},
	"serverInfo" : {
		"host" : "berro-ubuntu",
		"port" : 27017,
		"version" : "3.0.7",
		"gitVersion" : "6ce7cbe8c6b899552dadd907604559806aa2e9bd"
	},
	"ok" : 1
}
```

Here we have a new SORT stage and stil have a "COLLSCAN" stage:
```javascript
> db.folks.find({"location.city":"preston","name.first":"lewis"}).sort({"email":1}).explain("executionStats")
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "users.folks",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"$and" : [
				{
					"location.city" : {
						"$eq" : "preston"
					}
				},
				{
					"name.first" : {
						"$eq" : "lewis"
					}
				}
			]
		},
		"winningPlan" : {
			"stage" : "SORT",
			"sortPattern" : {
				"email" : 1
			},
			"inputStage" : {
				"stage" : "COLLSCAN",
				"filter" : {
					"$and" : [
						{
							"location.city" : {
								"$eq" : "preston"
							}
						},
						{
							"name.first" : {
								"$eq" : "lewis"
							}
						}
					]
				},
				"direction" : "forward"
			}
		},
		"rejectedPlans" : [ ]
	},
	"executionStats" : {
		"executionSuccess" : true,
		"nReturned" : 6,
		"executionTimeMillis" : 78,
		"totalKeysExamined" : 0,
		"totalDocsExamined" : 57648,
		"executionStages" : {
			"stage" : "SORT",
			"nReturned" : 6,
			"executionTimeMillisEstimate" : 70,
			"works" : 57658,
			"advanced" : 6,
			"needTime" : 57650,
			"needFetch" : 0,
			"saveState" : 450,
			"restoreState" : 450,
			"isEOF" : 1,
			"invalidates" : 0,
			"sortPattern" : {
				"email" : 1
			},
			"memUsage" : 4812,
			"memLimit" : 33554432,
			"inputStage" : {
				"stage" : "COLLSCAN",
				"filter" : {
					"$and" : [
						{
							"location.city" : {
								"$eq" : "preston"
							}
						},
						{
							"name.first" : {
								"$eq" : "lewis"
							}
						}
					]
				},
				"nReturned" : 6,
				"executionTimeMillisEstimate" : 70,
				"works" : 57650,
				"advanced" : 6,
				"needTime" : 57643,
				"needFetch" : 0,
				"saveState" : 450,
				"restoreState" : 450,
				"isEOF" : 1,
				"invalidates" : 0,
				"direction" : "forward",
				"docsExamined" : 57648
			}
		}
	},
	"serverInfo" : {
		"host" : "berro-ubuntu",
		"port" : 27017,
		"version" : "3.0.7",
		"gitVersion" : "6ce7cbe8c6b899552dadd907604559806aa2e9bd"
	},
	"ok" : 1
}
```

> Create index 
> db.folks.createIndex({"location.city":1})

Try again with index and check that COLLSCAN stage gone and we have a new "IXSCAN" stage:
```javascript
> db.folks.find({"location.city":"preston"}).explain("executionStats")
{
	"queryPlanner" : {
		"plannerVersion" : 1,
		"namespace" : "users.folks",
		"indexFilterSet" : false,
		"parsedQuery" : {
			"location.city" : {
				"$eq" : "preston"
			}
		},
		"winningPlan" : {
			"stage" : "FETCH",
			"inputStage" : {
				"stage" : "IXSCAN",
				"keyPattern" : {
					"location.city" : 1
				},
				"indexName" : "location.city_1",
				"isMultiKey" : false,
				"direction" : "forward",
				"indexBounds" : {
					"location.city" : [
						"[\"preston\", \"preston\"]"
					]
				}
			}
		},
		"rejectedPlans" : [ ]
	},
	"executionStats" : {
		"executionSuccess" : true,
		"nReturned" : 60,
		"executionTimeMillis" : 0,
		"totalKeysExamined" : 60,
		"totalDocsExamined" : 60,
		"executionStages" : {
			"stage" : "FETCH",
			"nReturned" : 60,
			"executionTimeMillisEstimate" : 0,
			"works" : 61,
			"advanced" : 60,
			"needTime" : 0,
			"needFetch" : 0,
			"saveState" : 0,
			"restoreState" : 0,
			"isEOF" : 1,
			"invalidates" : 0,
			"docsExamined" : 60,
			"alreadyHasObj" : 0,
			"inputStage" : {
				"stage" : "IXSCAN",
				"nReturned" : 60,
				"executionTimeMillisEstimate" : 0,
				"works" : 61,
				"advanced" : 60,
				"needTime" : 0,
				"needFetch" : 0,
				"saveState" : 0,
				"restoreState" : 0,
				"isEOF" : 1,
				"invalidates" : 0,
				"keyPattern" : {
					"location.city" : 1
				},
				"indexName" : "location.city_1",
				"isMultiKey" : false,
				"direction" : "forward",
				"indexBounds" : {
					"location.city" : [
						"[\"preston\", \"preston\"]"
					]
				},
				"keysExamined" : 60,
				"dupsTested" : 0,
				"dupsDropped" : 0,
				"seenInvalidated" : 0,
				"matchTested" : 0
			}
		}
	},
	"serverInfo" : {
		"host" : "berro-ubuntu",
		"port" : 27017,
		"version" : "3.0.7",
		"gitVersion" : "6ce7cbe8c6b899552dadd907604559806aa2e9bd"
	},
	"ok" : 1
}

```


### Conpound index 

Try these. They are going to use last index created:
> db.folks.find({"location.city":"preston"}).sort({email:1}).explain("executionStats")

> db.folks.find({"location.city":"preston","name.first":"lewis"}).sort({"email":1}).explain("executionStats")


> Create a new index 
> db.folks.createIndex({"location.city":1, "name.first":1})

This one uses first index:
> db.folks.find({"location.city":"preston"}).sort({email:1}).explain("executionStats")

But this uses compound index:
> db.folks.find({"location.city":"preston","name.first":"lewis"}).sort({"email":1}).explain("executionStats")

Here we have a collscan. Maybe, you can think that counpound index can be used, but order of indexes matter in MongoDB
> db.folks.find({"name.first":"lewis"}).sort({"email":1}).explain("executionStats")




### Object index 

None of these are going to use last indexes created:
> db.folks.find({name: {title: "mr", first: "melvin"}}).explain("executionStats")

> db.folks.find({name: {title: "mr", first: "melvin", last:"lynch"}}).explain("executionStats")


> Create index 
> db.folks.createIndex({"name":1})

#### Odd
Sometimes it not worth it cause we don't have all document as query criteria



### Multi key index 

To test multi key index we are going to put phone and cell into an array in each document in a new collection called folkstest

```javascript
db.folks.aggregate(
[
  {
    $project: {
      nationality: 1,
      gender: 1,
      name: 1,
      location: 1,
      email: 1,
      username: 1,
      password: 1,
      salt: 1,
      md5: 1,
      sha1: 1,
      sha256: 1,
      registered: 1,
      dob: 1,
      phone: 1,
      cell: 1,
      contactNumbers : { "$literal": ["phone","cell"] },
      NINO: 1,
      picture: 1
    }
  },
  {
    $unwind: "$contactNumbers"
  },
  { "$group": {
        "_id": "$_id",

        "contactNumbers": {
            "$push": {
                "$cond": [
                    { "$eq": [ "$contactNumbers", "phone" ] },
                    "$phone",
                    "$cell"
                ]
            }
        },

	"gender": { "$first": "$gender" },
	"nationality": { "$first": "$nationality" },
	"name": { "$first": "$name" },
	"location": { "$first": "$location" },
	"email": { "$first": "$email" },
	"username": { "$first": "$username" },
	"password": { "$first": "$password" },
	"salt": { "$first": "$salt" },
	"md5": { "$first": "$md5" },
	"sha1": { "$first": "$sha1" },
	"sha256": { "$first": "$sha256" },
	"registered": { "$first": "$registered" },
	"dob": { "$first": "$dob" },
	"NINO": { "$first": "$NINO" },
	"picture": { "$first": "$picture" }
      }
   },

  {
    $out: "folkstest"
  }
], 
{
  allowDiskUse:true,
  cursor:{}
})
```

We need "allowDiskUse:true" then mongo can write to temporary files and execute aggregation with huge data:
http://stackoverflow.com/questions/26069601/how-to-aggregate-on-huge-array-in-mongodb
```javascript
assert: command failed: {
	"errmsg" : "exception: Exceeded memory limit for $group, but didn't allow external sort. Pass allowDiskUse:true to opt in.",
	"code" : 16945,
	"ok" : 0
} : aggregate failed
```


Try these without index:
> db.folkstest.find({contactNumbers:"0721-229-194"}).explain("allPlansExecution")

> db.folkstest.find({contactNumbers:{$in:["0721-229-194","0786-591-470"]}}).explain("allPlansExecution")

> db.folkstest.find({contactNumbers:{$in:["0721-229-194","0786-591-470"]}},{_id:0,contactNumbers:1}).explain("allPlansExecution")

> Create index 
> db.folkstest.createIndex({"contactNumbers":1})

Try those queries again and check that we have IXSCAN stages


### Text indexes 

Getting text data from http://api.icndb.com/jokes/random/500. You are going to get one documents like this:

```javascript
...
{
  "type": "success",
  "value": [
    {
      "id": 77,
      "joke": "Chuck Norris can divide by zero.",
      "categories": [
        
      ]
    },
    {
      "id": 375,
      "joke": "After taking a steroids test doctors informed Chuck Norris that he had tested positive. He laughed upon receiving this information, and said &quot;of course my urine tested positive, what do you think they make steroids from?&quot;",
      "categories": [
        
      ]
    },
    {
      "id": 171,
      "joke": "Chuck Norris can set ants on fire with a magnifying glass. At night.",
      "categories": [
        
      ]
    }
  ]
}
...
```

Format those documents and put it in other collection called chuckjokes:
```javascript
db.chuck.aggregate(
[
  {
    $unwind: "$value"
  },
  {
    $project: {
      _id: "$value.id",
      joke: "$value.joke",
      categories: "$value.categories"
    }
  },
  {
    $out: "chuckjokes"
  }
])
```

That is how new document schema seems like:
```javascript
{
	"_id" : 561,
	"joke" : "Chuck Norris doesn't need an account. He just logs in.",
	"categories" : [ ]
}
```

You can use regular expression:

> db.chuckjokes.find({joke:/need/}).explain("allPlansExecution")

or text index:

> db.chuckjokes.createIndex({joke:"text"})

> db.chuckjokes.find({$text:{$search:"need"}}).explain("allPlansExecution")

It was weird for me cause I got a better performance with regexp rather than text index in my 500k db. But, I guess that index is getting better when database grows. Any thoughts?

Hope it helps

Berro
