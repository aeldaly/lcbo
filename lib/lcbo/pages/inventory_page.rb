module LCBO
  class InventoryPage

  # Configure GraphQL endpoint using the basic HTTP network adapter.
    GRAPHQL_HTTP = GraphQL::Client::HTTP.new("https://www.lcbo.com/graphql") do
      def headers(context)
        {}
      end
    end

    GRAPHQL_SCHEMA = GraphQL::Client.load_schema("./schema.json")

    GRAPHQL_CLIENT = GraphQL::Client.new(schema: GRAPHQL_SCHEMA, execute: GRAPHQL_HTTP)

    GRAPHQL_PRODUCT_STORE_INV_QUERY = GRAPHQL_CLIENT.parse <<-'GRAPHQL'
query($sku: String!) {
  getProductStoreInventory(sku: $sku) {
    error
    status
    store {
      name
      stloc_identifier
      store_qty
      available_sdp
    }
  }
}
    GRAPHQL


    include CrawlKit::Page
    # LEFT BLANK so we don't try and scrape html page
    uri 'https://www.lcbo.com/en/storeinventory/?sku={sku}'

    # on :after_parse,  :perform_graphql_request


    # FOR TESTING
    # emits :xdoc; doc; end
    # emits :graphql_response do
    #   @graphql_response.to_hash['data']['getProductStoreInventory']['store']
    # end

    emits :product_url do
      doc.css('h1 a[title="Product Name"]')[0].attr(:href) rescue nil
    end

    emits :sku do
      query_params[:sku]
    end

    emits :product_id do
      query_params[:sku]
    end

    emits :inventory_count do
      # sums all quantities in inventory json
      inventory_json.inject(0){|s,e| s+= e[6].to_i; s}
    end



    emits :inventories do
      inventory_json.map do |x|
        {
          quantity: x[6].to_i,
          address: x[2].upcase,
          store_id: x[5]
        }
      end
    rescue
      []
    end


    def inventory_json
      if !doc.css(".inventory_empty_div").empty?
        # No inventory available... not an error
        @inventory_array = []
      else
        # ["City","Intersection","Address Line 1","Address Line 2","Phone Number","Store Number","Available Inventory"]
        @inventory_array ||= JSON.parse doc.to_s.gsub(/[\n\t]/, '').match(/\"storeList\"\:(\[.*\])\, +\"sku\"/)[1]

        @inventory_array ||= []
      end


      # GRAPHQL inventory is not acurate (it returns all zeros for every store)
      # @graphql_response.to_hash['data']['store']
    end


    def graphql_inventories
      @graphql_response.to_hash['data']['getProductStoreInventory']['store'].map do |x|
        {
          quantity: x["store_qty"].to_i,
          # address: x[2].upcase,
          store_id: x["stloc_identifier"]
        }
      end
    rescue
      []
    end

    def perform_graphql_request
      @graphql_response ||= GRAPHQL_CLIENT.query(GRAPHQL_PRODUCT_STORE_INV_QUERY, variables: {sku: self.sku})
    end

  end
end
