// aws-sdk is provided by aws for lambdas by default
const AWS = require('aws-sdk');
const response = require('./cfn-response');
exports.handler = function(event, context, callback) {
  if (event.RequestType === 'Delete') {
    response.send(event, context, response.SUCCESS);
  } else {
    const glue = new AWS.Glue();
    glue.startCrawler({ Name: process.env.CRAWLER_NAME }, function(err, data) {
      if (err) {
        const responseData = JSON.parse(this.httpResponse.body);
        if (responseData['__type'] == 'CrawlerRunningException') {
          callback(null, responseData.Message);
        } else {
          const responseString = JSON.stringify(responseData);
          if (event.ResponseURL) {
            response.send(event, context, response.FAILED,{ msg: responseString });
          } else {
            callback(responseString);
          }
        }
      }
      else {
        if (event.ResponseURL) {
          response.send(event, context, response.SUCCESS);
        } else {
          callback(null, response.SUCCESS);
        }
      }
    });
  }
};