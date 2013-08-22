**GitDB** is a RESTful HTTP network service for reading and writing to git repositories. It is implemented in Coffeescript and uses the **nodegit** Javascript **libgit2** bindings.

## What is it good for?

GitDB was originally designed for a **scalable**, git-backed, wiki. Typically, git-backed wikis host the web server and git repository on the same machine. This approach is difficult to scale: if your site gets popular and you need to add more web servers, you need also partition the git repository. To remedy this, GitDB wraps a git repository in a network service: now, the web server tier can be deployed in a normal shared-nothing configuration, communicating with GitDB over an HTTP REST interface; and the git tier can scale independently.

One reason to use git as a datastore is that it models well the revision history of a corpus of documents, as in a wiki -- but git is, at its core, a durable store for blobs; trees; and directed, acyclic graphs; with a variety of atomic read and write operations. So GitDB may be useful in a variety of contexts.

## Design goals

GitDB is designed to be both low latency and convenient. Its API:

* minimizes network round-trips
* supports compression ubiquitously
* support patch/delta get and set operations -- *not yet implemented*
* supports high concurrency thanks to an asynchronous programming model

Finally, the API conveniently supports a variety of atomic-write and snapshot-read operations.

## Performance

Although git was not designed for OLTP applications, it has very low latency (~1ms) for most common tasks, once the file-system cache is warm. Benchmarks will be forthcoming.

## API Preliminary

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

#### HTTP Verbs

GitDB uses the HTTP verbs with a fairly standard interpretation. `POST` creates a new resource, `PUT` replaces a resource, `PATCH` updates a resource, and `DELETE` deletes a resource.

Every resource in git is immutable except for references (e.g., a branch). So `PUT`, `PATCH`, and `DELETE`, are only meaningful relative to a reference: that is, you may modify some files on a branch, but what happens under the covers is that new trees and blobs are created, a new commit is created, and the reference is updated to point to the new commit.

## API Documentation

### Repositories

Metadata about repositories hosted by GitDB.

* [`GET /repos`](https://github.com/nkallen/gitdb/wiki/Repositories#get-all-repositories)
* [`GET /repos/:repo`](https://github.com/nkallen/gitdb/wiki/Repositories#get-a-repository)

### References

References are typically tags and branches; in theory, they can "refer" to any kind of git object, but usually they refer to commits. "Tags" are usually immutable, whereas branches often change.

* [`GET /repo/:repo/refs`](https://github.com/nkallen/gitdb/wiki/References#get-all-references)
* [`GET /repo/:repo/refs/:ref`](https://github.com/nkallen/gitdb/wiki/References#get-a-reference)

You may want to view a file on a branch, or view the history (`git log`) of a branch:

* [`GET /repo/:repo/refs/:ref/log`](https://github.com/nkallen/gitdb/wiki/References#get-the-history-of-a-reference)
* [`GET /repo/:repo/refs/:ref/tree/*`](https://github.com/nkallen/gitdb/wiki/References#get-a-tree-relative-to-a-reference)

"Head refs" are how branches keep track of the current commit. You can make a commit to a branch in two ways: either you can update many files at once using `patch`, or you can edit just one file to make a more precise commit, using `put`. In either case, these are atomic operations; all updates succeed or none succeed, and the `If-Match` HTTP header to perform a kind of compare-and-set.

* [`PATCH /repo/:repo/refs/:ref`](https://github.com/nkallen/gitdb/wiki/References#make-a-commit-to-a-reference)
* [`PUT /repo/:repo/refs/:ref/tree/*`](https://github.com/nkallen/gitdb/wiki/References#create-or-update-a-file-on-a-reference)

### Commits

Individual commit objects can be part of a branch's (or reference's) history, or they can float off in the aether. Note: creating a new commit is idempotent.

* [`GET /repo/:repo/commits/:sha`](https://github.com/nkallen/gitdb/wiki/Commits#get-a-commit)
* [`POST /repo/:repo/commits`](https://github.com/nkallen/gitdb/wiki/Commits#create-a-commit)

A branch potentially changes over time, but you can easily read the file system over many http requests at a specific point in time -- like a snapshot-read.

* [`GET /repo/:repo/commits/:sha/tree/*`](https://github.com/nkallen/gitdb/wiki/Commits#get-a-tree-relative-to-a-commit)

### Blobs

Blobs are how files are represented in git; they can be binary and very large. Since they are referenced by their sha fingerprint, they are immutable.

* [`GET /repo/:repo/blobs/:sha`](https://github.com/nkallen/gitdb/wiki/Blobs#get-a-blob)
* [`POST /repo/:repo/blobs`](https://github.com/nkallen/gitdb/wiki/Blobs#create-a-blob) -- *not yet implemented*

### Trees

Trees represent the directory structure. Typically you will want to read a tree relative to a commit or a reference, but creating trees (and blobs) directly can sometimes be useful. For exampe, you may want to make several modifications over several HTTP requests, and then later commit them all atomically.

* [`GET /repo/:repo/trees/:sha/*`](https://github.com/nkallen/gitdb/wiki/Trees#get-a-tree)
* [`POST /repo/:repo/trees`](https://github.com/nkallen/gitdb/wiki/Trees#create-a-tree) -- *not yet implemented*
