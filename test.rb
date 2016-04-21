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

def do_in_child
  # http://stackoverflow.com/a/1076445
  read, write = IO.pipe

  pid = fork do
    read.close
    result = yield
    Marshal.dump(result, write)
    exit!(0) # skips exit handlers.
  end

  write.close
  result = read.read
  Process.wait(pid)
  raise 'child failed' if result.empty?
  Marshal.load(result)
end

describe 'runner' do
  i_suck_and_my_tests_are_order_dependent!

  it 'returns an error both for sandboxed brakeman and rails_best_practices' do
    file = 'app/controllers/test_controller.rb'

    errors = []
    errors += do_in_child do
      require 'brakeman'
      run_brakeman(file).take(1)
    end

    errors += do_in_child do
      require 'rails_best_practices'
      run_rails_best_practices(file)
    end

    errors.must_equal [
                        'Possible unprotected redirect',
                        'remove unused methods (TestController#index)'
                      ]
  end

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
