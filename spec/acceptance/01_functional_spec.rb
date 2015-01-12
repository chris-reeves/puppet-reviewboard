require 'spec_helper_acceptance'

describe 'access reviewboard' do
  it 'returns a web page' do
    response = command("curl -s -o /dev/null -D - 'http://localhost/reviewboard/r/' | head -1").stdout
    response.should match /200 OK/
  end
end

describe 'create review request' do
  it 'POSTs successfully' do
    response = command("curl -s -o /dev/null -D - --user admin:testing -d '' 'http://localhost/reviewboard/api/review-requests/' | head -1").stdout
    response.should match /201 CREATED/
  end
end
