require_relative '../../../app/api'
require 'rack/test'

module ExpenseTracker

  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def body
      JSON.parse(last_response.body)
    end

    def status
      last_response.status
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }
    let(:expense) { { 'some' => 'data' } }

    describe 'POST /expenses' do
      context 'When the expense is succesfully recorded' do
        before do
          allow(ledger).to receive(:record)
                       .with(expense)
                       .and_return(RecordResult.new(true, 417, nil))
        end

        it 'return the expense id' do
          post '/expenses', JSON.generate(expense)
          expect(body).to include('expense_id' => 417)
        end
        it 'responds with a 200 (OK)' do
          post '/expenses', JSON.generate(expense)
          expect(status).to eq 200
        end
      end

      context 'When the expense fails recording' do
        before do
          allow(ledger).to receive(:record)
                       .with(expense)
                       .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end
        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)
          expect(body).to include('error' => 'Expense incomplete')
        end
        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(status).to eq 422
        end
      end
    end

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        let(:coffee) do
          {
            'id' => 417,
            'payee' => 'Starbucks',
            'date' => '2017-06-10',
            'amount' => 6.50
          }
        end

        let(:zoo) do
          {
            'id' => 418,
            'payee' => 'Zoo',
            'date' => '2017-06-10',
            'amount' => 16.50
          }
        end

        before do
          expenses = [zoo, coffee]
          allow(ledger)
            .to receive(:expenses_on)
            .with('2017-06-10')
            .and_return(JSON.generate(expenses))
        end

        it 'returns the expense records as JSON' do
          get '/expenses/2017-06-10'
          expect(body).to include(coffee, zoo)
        end

        it 'responds with a 200 (OK)' do
          get 'expenses/2017-06-10'
          expect(status).to eq 200
        end
      end

      context 'when expenses do not exist on the given date' do
        before do
          expenses = []
          allow(ledger)
            .to receive(:expenses_on)
            .with('2017-06-10')
            .and_return(JSON.generate(expenses))
        end

        it 'returns an empty array' do
          get 'expenses/2017-06-10'
          expect(body).to eq []
        end

        it 'responds with a 200 (OK)' do
          get 'expenses/2017-06-10'
          expect(status).to eq 200
        end
      end
    end
  end
end
