var http = require('http');


var server = http.createServer(function(req, res){
    res.writeHead(200, {'Content-Type' : 'text/plain'});
    res.end('hello world');
}).listen(8787);

console.log('Server running ....');