show = (req, res) ->
  res.send(200, req.blob.content())

module.exports =
  show: show
