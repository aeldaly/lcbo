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

  def self.product(id)
    ProductPage.process(:id => id).as_hash
  end

  def self.store(id)
    StorePage.process(:id => id).as_hash
  end

  def self.inventory(internal_id, sku)
    InventoryPage.process(internal_id:internal_id, sku:sku).as_hash
  end

  def self.product_list(page_num)
    ProductListPage.process({}, :page => page_num).as_hash
  end

  def self.store_list
    StoreListPage.process({}, {}).as_hash
  end

end
