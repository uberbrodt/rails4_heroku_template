
Use it like this:

rails new [APP NAME] -T -B -m https://raw.github.com/uberbrodt/rails4_heroku_template/master/rails4_heroku.rb


What this does is prevent TestUnit stuff from being generated (because we use RSpec), and does not run Bundle Install
(the template runs it already so it gets access to some generators in the gems it includes)
