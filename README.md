**GitDB** is an HTTP network service on top of a GIT repository. It is implemented in Coffeescript and uses the **nodegit** Javascript **libgit2** bindings. 

The API is closely modeled on GitHub's HTTP API, with some minor divergences. This API is hypermedia in style, so some familiarity with custom media types and, of course, http verbs is a must.

Also, since GitDB wraps the "plumbing" rather than the "porcelain" of the Git API, if you are unfamiliar with Git's internals, it's best to start with [Chapter 8 of Pro Git]().
