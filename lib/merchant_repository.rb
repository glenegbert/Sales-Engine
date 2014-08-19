require_relative 'repository_parser'

class MerchantRepository

  attr_reader :merchants

  def initialize(file = './data/merchants.csv')
    @merchants = RepositoryParser.load(file, class_name: Merchant)
  end

  def inspect
     "#<#{self.class} #{@merchants.size} rows>"
  end

  def random
    merchants.shuffle.sample
  end

  def count
    merchants.count
  end

end