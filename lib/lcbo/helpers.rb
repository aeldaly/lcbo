module LCBO

  PAGE_TYPES = {
    :product      => 'ProductPage',
    :product_list => 'ProductListPage',
    :store_list   => 'StoreListPage',
    :store        => 'StorePage',
    :inventory    => 'InventoryPage'
  }

  def self.page(type)
    Object.const_get(PAGE_TYPES[type.to_sym])
  end

  def self.parse(page_type, response)
    page[page_type].parse(response)
  end


  def self.product(sku)
    ProductPage.process(sku:sku).as_hash
  end

  def self.inventory(sku)
    InventoryPage.process(sku:sku).as_hash
  end




  def self.store(id)
    StorePage.process(:id => id).as_hash
  end

  def self.product_list(page_num)
    ProductListPage.process({}, :page => page_num).as_hash
  end

  def self.store_list
    StoreListPage.process({}, {}).as_hash
  end

end
