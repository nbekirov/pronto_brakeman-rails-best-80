require 'minitest/autorun'
require 'pry'

def run_brakeman(file)
  result = Brakeman.run(
    app_path: '.',
    only_files: [file]
  )
  result.filtered_warnings.map(&:message)
end

def run_rails_best_practices(file)
  analyzer = RailsBestPractices::Analyzer.new(
    '.',
    'silent' => true,
    # 'debug' => true,
    'only' => [Regexp.new(file)]
  )

  analyzer.analyze
  analyzer.errors.map(&:message)
end

describe 'runner' do
  it 'return an error both for brakeman and rails_best_practices' do
    require 'brakeman'
    require 'rails_best_practices'

    file = 'app/controllers/test_controller.rb'

    errors = []
    errors += run_brakeman(file).take(1)
    errors += run_rails_best_practices(file)

    errors.must_equal [
                        'Possible unprotected redirect',
                        'remove unused methods (TestController#index)'
                      ]
  end
end
