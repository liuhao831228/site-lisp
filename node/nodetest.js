var http = require('http');

http.createServer(function(req, res){
  res.writeHead(200, {'Content-Type':'text/plain'});
  res.end('hello world\n');
  
}).listen(8787, "127.1.1.1");

console.log('Server running at http://127.1.1.1:8787/');

