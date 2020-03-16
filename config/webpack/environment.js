const { environment } = require('@rails/webpacker')
const ExtractTextPlugin = require('extract-text-webpack-plugin');

const lessLoader = {
  test: /\.less$/,
  use: ["style-loader", "css-loader", "less-loader"]
}

// Insert json loader at the end of list
environment.loaders.append('less', lessLoader)

const customConfig = require('./custom')
// Merge custom config
environment.config.merge(customConfig)


module.exports = environment
