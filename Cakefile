fs = require 'fs'
exec  = (require 'child_process').exec

buildCompile = (tplfile)->
  files = fs.readdirSync 'src/compile'
  velocity = ''
  files.forEach (file) ->
    if file isnt 'index.js'
      text = (fs.readFileSync "./src/compile/#{file}").toString()
      text = text.replace 'module.exports = ', "/** file: ./src/compile/#{file}*/\n!"
      text = text.replace /;\s*$/ , "(Velocity, utils);\n\n"
      velocity += text

  helper = (fs.readFileSync "./src/helper/text.js").toString()
  helper = helper.replace 'module.exports = ', '!'
  helper = helper.replace /;\s*$/, "(Velocity.Helper, utils);"

  tpl = (fs.readFileSync tplfile).toString()
  tpl = tpl.replace '{helper}', helper
  tpl = tpl.replace '{velocity}', velocity
  fs.writeFileSync 'build/velocity/index.js', tpl
  console.log 'build compile success, file at build/velocity/'

buildParse = ()->
  comd = 'jison velocity.yy velocity.l && mv velocity.js index.js'
  parse = exec comd, {cwd: "./src/parse/"}, (error, stdout, stderr)->
    console.log 'finish parse'
    if error isnt null
      console.log 'exec error: ' + error

#编译为velocity语法分析器
task 'parse', 'rebuild the Jison parser', (options) ->
  do buildParse

#编译为kissy的模块
task 'build', 'build velocity for kissy', (options) ->
  buildCompile "./build/tpl.js"
  do buildParse
  parseStr = (fs.readFileSync './src/parse/index.js').toString()
  fs.writeFileSync './build/velocity/parse.js', "
  KISSY.add(function(S){
    #{parseStr}
    return velocity;
  });
  "
  console.log 'build parse to build/velocity/parse.js'
