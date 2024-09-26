ENV["RACK_ENV"] = "test"
# assigning environment variable to "test" to let Sinatra and Rack
# know if the code is being tested and whether or not to start a web server.
# We dont want to start a web server while testing.

require "minitest/autorun"
require "rack/test"
# this is loading Minitest, and configuring it to
# automatically run any defined tests.
# "rack/test" loads `Rack::Test` helper methods

require_relative "../cms"
# we require access to our application file to be
# able to run tests on it.

class CMSTest < Minitest::Test
# our definded CMS class inherits behaviours from `Minitest::Test`

include Rack::Test::Methods
# we are mixing in helper methods for testing from Rack.

  def app
    Sinatra::Application
  end
  # Rack test methods expect an `app` method that returns
  # an instance of a Rack application.
  
  def test_index
    
    get "/"
    assert_equal 200, last_response.status
    # `last_response` gives us access to an instance of
    # `Rack::MockResponse`, which is more or less a simulation
    # of a response from a server. The simulation gives us
    # `status`, `body`, and `[]` methods for accessing the simulations
    # status code, body, and headers.
    
  end
  
  def test_filename
    
    get "/:filename"
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    # assert_includes last_response.body, "about.md"
    # assert_includes last_response.body, "changes.txt"
    # assert_includes last_response.body, "history.txt"
  end
  
  def test_viewing_text_document
    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 0.95 released"
  end
  
  def test_document_not_found
    get "/notafile.ext" # Attempt to access a nonexistent file
  
    assert_equal 302, last_response.status # Assert that the user was redirected
  
    get last_response["Location"] # Request the page that the user was redirected to
  
    assert_equal 200, last_response.status
    assert_includes last_response.body, "notafile.ext does not exist"
  
    get "/" # Reload the page
    refute_includes last_response.body, "notafile.ext does not exist" # Assert that our message has been removed
  end
  
  # test/cms_test.rb
  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end
  

end