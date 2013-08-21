**GitDB** is a RESTful HTTP network service for reading and writing to git repositories. It is implemented in Coffeescript and uses the **nodegit** Javascript **libgit2** bindings.

## What is it good for?

GitDB was originally designed for a **scalable**, git-backed, wiki. Typically, git-backed wikis host the web server and git repository on the same machine. This approach is difficult to scale: if your site gets popular and you need to add more web servers, you need also partition the git repository. To remedy this, GitDB wraps a git repository in a network service: now, the web server tier can be deployed in a normal shared-nothing configuration, communicating with GitDB over an HTTP REST interface; and the git tier can scale independently.

One reason to use git as a datastore is that it models well the revision history of a corpus of documents, as in a wiki -- but git is, at its core, a durable store for blobs; trees; and directed, acyclic graphs; with a variety of atomic read and write operations. So GitDB may be useful in a variety of contexts.

## Design goals

GitDB is designed to be both low latency and convenient. Its API:

. minimizes network round-trips
. supports compression ubiquitously
. support patch/delta get and set operations
. supports high concurrency thanks to an asynchronous programming model

Finally, the API conveniently supports a variety of atomic-write and snapshot-read operations.

## Performance

Although git was not designed for OLTP applications, it has very low latency (~1ms) for most common tasks, once the file-system cache is warm. Benchmarks will be forthcoming.

## The API

The API is inspired GitHub's HTTP API but it offers more flexibility for OLTP applications. The API is hypermedia in style, so some familiarity with custom media types and, of course, HTTP verbs is a must.

This document assumes some fmailiarity with Git's internals; check out [Chapter 9 of Pro Git](http://git-scm.com/book/en/Git-Internals) first if you are unfamiliar with Git's object model.

### Hypermedia

GitDB aims to have a "hypermedia" API. In theory, [hypermedia APIs](http://roy.gbiv.com/untangled/2008/rest-apis-must-be-) loosely couple clients and servers. The loose coupling is provided by hyperlinking and content negotiation.

#### Content-Negotiation and Media-Types

GitDB provides a `text/html` interface, an `application/json` interface, and a few custom, "vendor" media-types, such as `application/vnd.gitdb.raw`. This last is used for retrieving the "raw" contents of a blob, i.e., the contents of a file without any metadata. It is be useful for very large files, where wrapping the a file in JSON would be computationally expensive to parse.

The `json` and vendor media types constitute the "API", while the `html` media type is browsable in your favorite browser. The URL structure and semantics of the HTTP verbs (`PUT`, `GET`, etc.) are identical across media types, so the system is partially "self-documenting".

#### Hyperlinking

`application/json` media may have one or more `*_url` properties linking to other resources. This is exactly analogous to `<a>` tags in html. These are provided so API clients don’t need to explicitly construct URLs. The `*` in `*_url` will be a link relation; for example, a repository is linked to its references by its `ref_url` attribute. For example, here is the JSON of a repository:

      {
        "url": "/repos/Perseus",
        "refs_url": "/repos/Perseus/refs"
      }

Whether you choose to follow links or construct them on your own is a practical decision. Following links is resilient to some API change: in principle, you can simply start at the root resources (`/`) and traverse to any other resource without ever hardcoding a URL in your source code. In practice this adds more network round-trips, at least at startup.

### Repository API

#### Get all repositories

    GET /repos

##### Response

    [
      {
        "url": "/repos/Perseus",
        "refs_url": "/repos/Perseus/refs"
      },
      {
        "url": "/repos/bootstrap",
        "refs_url": "/repos/bootstrap/refs"
      },
      {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    ]

#### Get a repo

    GET /repos/:repo

##### Response

    {
      "url": "/repos/gitdb",
      "refs_url": "/repos/gitdb/refs"
    }

### References API

#### Get all references

    GET /repos/:repo/refs

##### Response

    [
      {
        "name": "refs/remotes/origin/master",
        "url": "/repos/gitdb/refs/remotes/origin/master"
      },
      {
        "name": "refs/heads/master",
        "url": "/repos/gitdb/refs/heads/master"
      },
      {
        "name": "refs/remotes/origin/HEAD",
        "url": "/repos/gitdb/refs/remotes/origin/HEAD"
      }
    ]

#### Get a reference

    GET /repos/:repo/refs/:ref

##### Response

The data at this endpoint is much richer than for listing all references, since the data for a reference is one random access in storage.

    {
      "name": "refs/heads/master",
      "type": 1,
      "object": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7"
      },
      "url": "/repos/gitdb/refs/heads/master",
      "commits_url": "/repos/gitdb/refs/heads/master/commits",
      "tree_url": "/repos/gitdb/refs/heads/master/tree/",
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

#### Get history of a reference.

Analogous to `git log`. Note that it is one random access to storage for each entry, plus a topological sort, so this resource is typically both IO and CPU intensive.

    GET /repos/:repo/refs/heads/:ref/commits

##### Response

    [
      {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      {
        "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
        "message": "Urls provided in json\n",
        "author": {
          "date": "2013-08-20T14:07:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T14:07:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "73720a4c31acc9563d65483614b46901315646c1"
        },
        "parents": [
          {
            "sha": "47c45a658a6a6ff3a3d6b78cd30d8dc05eb49045",
            "url": "/repos/gitdb/commits/47c45a658a6a6ff3a3d6b78cd30d8dc05eb49045"
          }
        ],
        "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
        "tree_url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      }
    ]

#### Make a commit to a reference

    POST /repos/:repo/refs/:ref/commits

##### Parameters

###### parents

Array of the SHAs of the commits that were the parents of this commit.

###### message

String of the commit message

###### tree

Array of hashes representing changes to the file-sysetm relative to the parent commit. Supported encodings for the content include `ascii`, `utf8`, and `base64`.

    "tree": [
      {
        "path": "README.md",
        "content": "Get on the bus, Gus",
        "encoding": "utf8",
        "filemode": 33188
      },
      {
        "path": "lib/foo.coffee",
        "content": "Make a new plan, Stan",
        "encoding": "utf8",
        "filemode": 33188
      }
    ]

###### author

Hash representing author of the code in the commit.

      "author": {
        "name": "Scott Chacon",
        "email": "schacon@gmail.com",
        "date": "2008-07-09T16:13:30+12:00"
      }

###### committer

Same format as author; represents the user who performed the commit.

##### Example Input

    {
      "message": "a new commit",
      "parents": ["73720a4c31acc9563d65483614b46901315646c1"],
      "author": {
        "name": "Scott Chacon",
        "email": "schacon@gmail.com",
        "date": "2008-07-09T16:13:30+12:00"
      },
      "committer": {
        "name": "Scott Chacon",
        "email": "schacon@gmail.com",
        "date": "2008-07-09T16:13:30+12:00"
      },
      "tree": [
        {
          "path": "README.md",
          "content": "Get on the bus, Gus",
          "encoding": "utf8",
          "filemode": 33188
        },
        {
          "path": "lib/foo.coffee",
          "content": "Make a new plan, Stan",
          "encoding": "utf8",
          "filemode": 33188
        }
      ]
    }

##### Response

    201 CREATED
    Location: /repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b

    {
      "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
      "message": "Urls provided in json\n",
      "author": {
        "date": "2013-08-20T14:07:42.000Z",
        "name": "Nick Kallen",
        "email": "socialmediamaster9000@gmail.com"
      },
      "committer": {
        "date": "2013-08-20T14:07:42.000Z",
        "name": "Nick Kallen",
        "email": "socialmediamaster9000@gmail.com"
      },
      "tree": {
        "sha": "73720a4c31acc9563d65483614b46901315646c1"
      },
      "parents": [
        {
          "sha": "47c45a658a6a6ff3a3d6b78cd30d8dc05eb49045",
          "url": "/repos/gitdb/commits/47c45a658a6a6ff3a3d6b78cd30d8dc05eb49045"
        }
      ],
      "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
      "tree_url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b/tree/",
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

#### Get a tree, relative to a ref

A tree represents the state of the file system. A given element in the tree might be a tree itself (i.e., a directory) or a blob (i.e., a file in a directory) -- the response look different for these different types.

    GET /repos/:repo/refs/:ref/tree/*

##### Response for a tree

    {
      "name": "",
      "path": "",
      "type": "tree",
      "filemode": 16384,
      "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
      "ref_relative_url": "/repos/gitdb/refs/heads/master/tree/",
      "url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/",
      "tree": {
        "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312",
        "url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/",
        "entries": [
          {
            "name": ".gitignore",
            "path": ".gitignore",
            "type": "blob",
            "filemode": 33188,
            "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/.gitignore",
            "ref_relative_url": "/repos/gitdb/refs/heads/master/tree/.gitignore",
            "url": "/repos/gitdb/blobs/3a1651fa759ca2e1717993b8bb75f951a732ee43"
          },
          {
            "name": "README.md",
            "path": "README.md",
            "type": "blob",
            "filemode": 33188,
            "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/README.md",
            "ref_relative_url": "/repos/gitdb/refs/heads/master/tree/README.md",
            "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8"
          }
        ]
      },
      "commit": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "ref": {
        "name": "refs/heads/master",
        "type": 1,
        "object": {
          "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7"
        },
        "url": "/repos/gitdb/refs/heads/master",
        "commits_url": "/repos/gitdb/refs/heads/master/commits",
        "tree_url": "/repos/gitdb/refs/heads/master/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

##### Response for a blob

Since blobs can be any arbitrary binary data, the input and responses for the blob API is returned encoded. Currently all data is base64 encoded, but for future compatibility, please use the `encoding` field when decoding data. Note that the media type `application/vnd.gitdb.raw` is also supported for blobs.

    {
      "name": "README.md",
      "path": "README.md",
      "type": "blob",
      "filemode": 33188,
      "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/README.md",
      "ref_relative_url": "/repos/gitdb/refs/heads/master/tree/README.md",
      "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8",
      "blob": {
        "filemode": 33188,
        "encoding": "base64",
        "size": 1276,
        "content": "KipHaXREQioqIGlzIGFuIEh...",
        "sha": "5c5ac45d9513562cc96e8e7021a8064009451ed8",
        "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8"
      },
      "commit": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "ref": {
        "name": "refs/heads/master",
        "type": 1,
        "object": {
          "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7"
        },
        "url": "/repos/gitdb/refs/heads/master",
        "commits_url": "/repos/gitdb/refs/heads/master/commits",
        "tree_url": "/repos/gitdb/refs/heads/master/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

### Blobs

#### Get a Blob

Since blobs can be any arbitrary binary data, the input and responses for the blob API is returned encoded. Currently all data is base64 encoded, but for future compatibility, please use the `encoding` field when decoding data. Note that the media type `application/vnd.gitdb.raw` is also supported for blobs.

    GET /repos/:repo/blobs/:sha

##### Response

    {
      "filemode": 33188,
      "encoding": "base64",
      "size": 1276,
      "content": "KipHaXREQioqIGl...",
      "sha": "5c5ac45d9513562cc96e8e7021a8064009451ed8",
      "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8",
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

### Commits

#### Get a commit

    GET /repos/:repo/commits/:sha

##### Response

    {
      "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
      "message": "Urls provided in json\n",
      "author": {
        "date": "2013-08-20T14:07:42.000Z",
        "name": "Nick Kallen",
        "email": "socialmediamaster9000@gmail.com"
      },
      "committer": {
        "date": "2013-08-20T14:07:42.000Z",
        "name": "Nick Kallen",
        "email": "socialmediamaster9000@gmail.com"
      },
      "tree": {
        "sha": "73720a4c31acc9563d65483614b46901315646c1"
      },
      "parents": [
        {
          "sha": "47c45a658a6a6ff3a3d6b78cd30d8dc05eb49045",
          "url": "/repos/gitdb/commits/47c45a658a6a6ff3a3d6b78cd30d8dc05eb49045"
        }
      ],
      "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
      "tree_url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b/tree/",
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

#### Get a tree, relative to a commit

A tree represents the state of the file system. A given element in the tree might be a tree itself (i.e., a directory) or a blob (i.e., a file in a directory) -- the response look different for these different types.

    GET /repos/:repo/commits/tree/:sha/*

##### Response for a tree

    {
      "name": "",
      "path": "",
      "type": "tree",
      "filemode": 16384,
      "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
      "url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/",
      "tree": {
        "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312",
        "url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/",
        "entries": [
          {
            "name": ".gitignore",
            "path": ".gitignore",
            "type": "blob",
            "filemode": 33188,
            "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/.gitignore",
            "url": "/repos/gitdb/blobs/3a1651fa759ca2e1717993b8bb75f951a732ee43"
          },
          {
            "name": "README.md",
            "path": "README.md",
            "type": "blob",
            "filemode": 33188,
            "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/README.md",
            "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8"
          }
        ]
      },
      "commit": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

##### Response for a blob

    {
      "name": "README.md",
      "path": "README.md",
      "type": "blob",
      "filemode": 33188,
      "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/README.md",
      "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8",
      "blob": {
        "filemode": 33188,
        "encoding": "base64",
        "size": 1276,
        "content": "KipHaXREQioqI...",
        "sha": "5c5ac45d9513562cc96e8e7021a8064009451ed8",
        "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8"
      },
      "commit": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

### Trees

#### Get a tree

A tree represents the state of the file system. A given element in the tree might be a tree itself (i.e., a directory) or a blob (i.e., a file in a directory) -- the response look different for these different types.

    GET /repos/:repo/trees/:sha/*

##### Response for a tree

    {
      "name": "",
      "path": "",
      "type": "tree",
      "filemode": 16384,
      "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
      "url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/",
      "tree": {
        "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312",
        "url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/",
        "entries": [
          {
            "name": ".gitignore",
            "path": ".gitignore",
            "type": "blob",
            "filemode": 33188,
            "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/.gitignore",
            "url": "/repos/gitdb/blobs/3a1651fa759ca2e1717993b8bb75f951a732ee43"
          },
          {
            "name": "README.md",
            "path": "README.md",
            "type": "blob",
            "filemode": 33188,
            "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/README.md",
            "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8"
          }
        ]
      },
      "commit": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }

##### Response for a blob

    {
      "name": "README.md",
      "path": "README.md",
      "type": "blob",
      "filemode": 33188,
      "commit_relative_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/README.md",
      "tree_relative_url": "/repos/gitdb/trees/93fb384f1f8bfac23a2fbef7f4c40a345a0fd312/README.md",
      "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8",
      "blob": {
        "filemode": 33188,
        "encoding": "base64",
        "size": 1276,
        "content": "KipHaXREQioq..",
        "sha": "5c5ac45d9513562cc96e8e7021a8064009451ed8",
        "url": "/repos/gitdb/blobs/5c5ac45d9513562cc96e8e7021a8064009451ed8"
      },
      "commit": {
        "sha": "38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "message": "Better web navigation\n",
        "author": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "committer": {
          "date": "2013-08-20T15:54:42.000Z",
          "name": "Nick Kallen",
          "email": "socialmediamaster9000@gmail.com"
        },
        "tree": {
          "sha": "93fb384f1f8bfac23a2fbef7f4c40a345a0fd312"
        },
        "parents": [
          {
            "sha": "a3ba5a6e314ed63571e01677463164cb7a8a1e9b",
            "url": "/repos/gitdb/commits/a3ba5a6e314ed63571e01677463164cb7a8a1e9b"
          }
        ],
        "url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7",
        "tree_url": "/repos/gitdb/commits/38f8d228f43f53bc42a77d5821aece4f09e66ca7/tree/",
        "repo": {
          "url": "/repos/gitdb",
          "refs_url": "/repos/gitdb/refs"
        }
      },
      "repo": {
        "url": "/repos/gitdb",
        "refs_url": "/repos/gitdb/refs"
      }
    }