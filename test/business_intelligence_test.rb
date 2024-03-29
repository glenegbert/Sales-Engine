require_relative 'test_helper'
require 'date'
# require 'pry'

class BusinessIntelligenceTest< Minitest::Test
  attr_reader :engine

  def setup
    @engine = SalesEngine.new
    engine.startup
  end

# **********MERCHANT REPOSITORY BUSINESS INTELLIGENCE*************
  def test_merchant_repo_can_return_the_top_x_merchants_by_total_revenue
    merchant_repository = engine.merchant_repository

    assert_equal 8, merchant_repository.most_revenue(8).count
    assert_equal 18, merchant_repository.most_revenue(3).first.id
  end

  def test_merchant_repo_can_return_the_top_x_merchants_by_total_number_of_items
    merchant_repository = engine.merchant_repository

    assert_equal 8, merchant_repository.most_items(8).count
    assert_equal 1, merchant_repository.most_items(3).first.id
  end

  def test_merchant_repo_can_return_the_total_revenue_by_date
    date = Date.parse "Sun, 25 Mar 2012"
    merchant_repository = engine.merchant_repository

    assert_equal BigDecimal.new("21067").to_i, merchant_repository.revenue(date).to_i
  end


# ***********MERCHANT BUSINESS INTELLIGENCE***********

  def test_merchant_can_return_total_revenue_accross_all_transactions
    merchant = engine.merchant_repository.merchants.detect do |merchant|
      merchant.id == 1
    end

    assert_equal BigDecimal.new("24214.17"), merchant.revenue
  end

  def test_merchant_can_return_the_total_revenue_for_a_specific_date
    date = Date.parse "Sun, 25 Mar 2012"
    merchant = engine.merchant_repository.merchants.detect do |merchant|
      merchant.id == 1
    end

    assert_equal BigDecimal.new("21067").to_i, merchant.revenue(date).to_i
  end

  def test_merchant_returns_the_customer_who_has_conducted_the_most_successful_transactions
    merchant = engine.merchant_repository.merchants.detect do |merchant|
      merchant.id == 1
    end

    favorite_customer = merchant.favorite_customer
  end

  def test_merchant_returns_customers_with_pending_invoices
    merchant = engine.merchant_repository.merchants.detect do |merchant|
      merchant.id == 1
    end

    assert_equal 3, merchant.customers_with_pending_invoices.count
  end

# ***********ITEM BUSINESS INTELLIGENCE ******************
  def test_item_returns_the_date_with_the_most_sales_for_it_using_invoice_date
      item = engine.item_repository.items.detect do |item|
        item.id == 1
      end

      assert_equal "2012-03-10", item.best_day.to_s
  end


# ***********CUSTOMER BUSINESS INTELLIGENCE **************

  def test_customer_can_return_associated_customer_transactions
    customer = engine.customer_repository.find_by('id', 1)
    associated_transactions = customer.transactions
    assert_equal 8, associated_transactions.count
    assert_equal [1, 2, 3, 4, 5, 6, 7, 20], associated_transactions.map(&:id)
  end

  def test_customer_can_return_the_merchant_where_it_has_the_most_successful_transactions
    customer = engine.customer_repository.find_by('id', 1)
    assert_equal 38, customer.favorite_merchant.id
  end

  # ****************ITEM REPOSITORY TEST *********************
  def test_item_repository_can_return_the_top_x_items_ranked_by_revenue
    item_repository = engine.item_repository

    assert_equal 10, item_repository.most_revenue(10).count
    assert_equal 1, item_repository.most_revenue(10).first.id
  end

  def test_item_repository_can_return_the_top_x_items_ranked_by_total_number_sold
    item_repository = engine.item_repository

    assert_equal 10, item_repository.most_items(10).count
    assert_equal 1, item_repository.most_items(10).first.id
  end

  # ****************INVOICE REPOSITORY TEST**********************
  def test_invoice_repository_can_create_invoices_on_the_fly
    invoice_repository = engine.invoice_repository
    customer = engine.customer_repository.find_by('id', 1)
    merchant = engine.merchant_repository.merchants.detect {|merchant| merchant.id == 1}
    item1 = engine.item_repository.items.detect {|item| item.id == 1}
    item2 = engine.item_repository.items.detect {|item| item.id == 2}
    item3 = engine.item_repository.items.detect {|item| item.id == 3}


    new_invoice = invoice_repository.create(customer: customer, merchant: merchant, status: "shipped",
                         items: [item1, item2, item3])

    assert_equal 26, new_invoice.id
    assert invoice_repository.invoices.any?{|invoice| invoice.id == 26 && invoice.merchant_id == 1 &&
    invoice.customer_id == 1 && invoice.status == "shipped"}
  end

  def test_invoice_repository_creates_invoice_items_when_creating_invoices
    invoice_item_repository = engine.invoice_item_repository
    invoice_repository = engine.invoice_repository

    customer = engine.customer_repository.find_by('id', 1)
    merchant = engine.merchant_repository.merchants.detect {|merchant| merchant.id == 1}
    item1 = engine.item_repository.items.detect {|item| item.id == 1}
    item2 = engine.item_repository.items.detect {|item| item.id == 2}
    item3 = engine.item_repository.items.detect {|item| item.id == 2}


    new_invoice = invoice_repository.create(customer: customer, merchant: merchant, status: "shipped",
                         items: [item1, item2, item3])

    assert_equal 27, invoice_item_repository.count
    assert invoice_item_repository.invoice_items.any?{|invoice_item| invoice_item.id == 27 && invoice_item.item_id == 2 &&
    invoice_item.quantity == 2}
  end

  def test_when_an_invoice_is_charged_a_new_transaction_is_created
    invoice_repository = engine.invoice_repository
    transaction_repository = engine.transaction_repository
    customer = engine.customer_repository.find_by('id', 1)
    merchant = engine.merchant_repository.merchants.detect {|merchant| merchant.id == 1}
    item1 = engine.item_repository.items.detect {|item| item.id == 1}
    item2 = engine.item_repository.items.detect {|item| item.id == 2}
    item3 = engine.item_repository.items.detect {|item| item.id == 3}


    new_invoice = invoice_repository.create(customer: customer, merchant: merchant, status: "shipped",
                         items: [item1, item2, item3])

    new_invoice.charge(credit_card_number: "4444333322221111",
               credit_card_expiration: "10/13", result: "success")

    assert_equal 26, transaction_repository.count
    assert transaction_repository.transactions.any?{|transaction| transaction.id == 26 && transaction.credit_card_number == "4444333322221111"}
  end
end
