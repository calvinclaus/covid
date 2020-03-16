const path = require('path')

const customConfig = {
  plugins: [],
  resolve: {
    alias: {
     '../../theme.config': path.join(__dirname, '../../semantic-ui-themes/theme.config'),
      "../semantic-ui/site": path.join(__dirname, "../../semantic-ui-themes/site")
    }
  }
}

module.exports = customConfig

