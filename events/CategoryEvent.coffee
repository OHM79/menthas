module.exports.CategoryEvent = (app) ->
  _      = require 'underscore'
  path = require 'path'
  RSS = require 'rss'
  debug  = require('debug')('events/category')
  Category = app.get("models").Category
  Item = app.get("models").Item

  # デフォルト定数
  ITEM_SIZE = 25
  RSS_SIZE = 25
  SCORE_THRESHOLD = 3
  HOT_THRESHOLD = 5

  index: (req,res,next)->
    Category.getCategoriesList (err,list)->
      res.render "index",{
        categories: list
      }

  list: (req,res,next)->
    categoryName = req.params.category
    size = req.query.size ? ITEM_SIZE
    offset = req.query.offset ? 0
    score = req.query.score ? SCORE_THRESHOLD
    Category.findByName categoryName,(err,category)->
      if err || !category
        debug err
        return res.status(500).send
      Item.findByCategory category._id,score,size,offset,(err,result)->
        if err
          debug err
          return res.status(500).send
        return res.json {
          items: result
        }

  # 全カテゴリを対象に指定score以上のitemを取得する
  hotList: (req,res,next)->
    console.log "test"
    size = req.query.size ? ITEM_SIZE
    score = req.query.score ? HOT_THRESHOLD
    Item.findByScore score,size,(err,result)->
      if err
        debug err
        return res.status(500).send
      return res.json {
        items: result
      }

  rss: (req,res,next)->
    categoryName = req.params.category
    @_generateRSS categoryName,(err,result)->
      if err
        debug err
        return res.status(500).send
      res.send result

  _generateRSS: (categoryName,callback)->
    that = @
    if categoryName is "hot"
      Item.findByScore HOT_THRESHOLD, RSS_SIZE, (err,items)->
        return callback err if err
        callback null, that._convertItemsToRSS items,categoryName
    else
      Category.findByName categoryName,(err,category)->
        if err || !category
          return callback err
        Item.findByCategory category._id, SCORE_THRESHOLD, RSS_SIZE, 0, (err,items)->
          return callback err if err
          callback null, that._convertItemsToRSS items,categoryName

  _convertItemsToRSS: (items,category)->
    feed = new RSS
      title: 'Menthas.com'
      description: 'プログラマ向けのニュースキュレーションサービスです。'
      feed_url: "http://menthas.com/#{category}/rss.xml"
      site_url: 'http://menthas.com',
    _.each items,(item)->
      feed.item
        title: item.page.title
        description: item.page.description
        url: item.page.url
        date: item.page.timestamp
    return feed.xml()