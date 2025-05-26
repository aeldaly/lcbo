module LCBO
  class ProductPage

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

    GRAPHQL_PRODUCT_QUERY = GRAPHQL_CLIENT.parse <<-'GRAPHQL'
query($sku: String!){
  products(
    # search: "house"
    filter: {
      sku: {eq: $sku}
    }
    pageSize: 20
    currentPage: 1
    sort: {}
  ) {
    items {
      bv_avg_rating
      bv_avg_reviews
      canonical_url
      color
      country_of_manufacture
      created_at
      id
      image {
        url
      }
      lcbo_alcohol_percent
      lcbo_basic_price
      lcbo_kosher
      lcbo_producer_name
      lcbo_region_name
      lcbo_subregion_name
      lcbo_unit_volume
      lcbo_upc_number
      lcbo_varietal_name
      lcbo_vintage_release_date
      lcbo_vqa_code
      loyalty_offer
      loyalty_promo {
        loyalty_enddate
        loyalty_points
        type
      }
      manufacturer
      meta_description
      meta_keyword
      meta_title
      name
      only_x_left_in_stock
      price_range {
        maximum_price {
            regular_price {
              currency
              value
            }
            final_price {
              currency
              value              
            }
        }
        minimum_price {
          regular_price {
            currency
            value
          }
          final_price {
            currency
            value              
          }
          discount {
            amount_off
            percent_off
          }
        }
      }
      qty
      sku
      special_price
      special_to_date
      stock_status
      uid
    }
    page_info {
      current_page
      page_size
      total_pages
    }
    sort_fields {
      default
    }
    suggestions {
      search
    }
    total_count
  }
}
    GRAPHQL


    include CrawlKit::Page
    # LEFT BLANK so we don't try and scrape html page
    # uri 'https://www.lcbo.com/en/storeinventory/?sku={id}'

    on :after_parse,  :perform_graphql_request

    # FOR TESTING
    # emits :xdoc; doc; end
    # emits :graphql_response do
    #   @graphql_product_query_response.to_hash['data']['products']['items'][0]
    # end


    emits :url do
      # doc.css('link[rel=canonical]')[0].attr(:href) rescue nil
      "https://www.lcbo.com/en/#{graphql_product_hash['canonical_url']}"
    end

    def perform_graphql_request
      @graphql_product_query_response ||= GRAPHQL_CLIENT.query(GRAPHQL_PRODUCT_QUERY, variables: {sku: self.sku})
    end

    emits :sku do
      query_params[:sku].to_i
    end

    emits :code2 do
      # doc.css('meta[name="pageId"]')[0].attr(:content) rescue nil
    end

    emits :name do
      # CrawlKit::TitleCaseHelper[doc.css('title')[0].content.split(' | ').first]
      graphql_product_hash['name']
    end

    emits :country_of_manufacture do
      graphql_product_hash['country_of_manufacture']
    end

    emits :tags do
      # CrawlKit::TagHelper[
      #   name,
      #   primary_category,
      #   secondary_category,
      #   origin,
      #   producer_name,
      #   package_unit_type
      # ]
    end

    emits :price_in_cents do
      ((graphql_product_hash['special_price'] || graphql_product_hash['price_range']['minimum_price']['regular_price']['value']) * 100).round
    end

    emits :sale_price_in_cents do
      if graphql_product_hash['special_price']
        (graphql_product_hash['special_price'] * 100).round
      else
        0
      end
    end

    emits :regular_price_in_cents do
      (graphql_product_hash['price_range']['minimum_price']['regular_price']['value'] * 100).round
    end

    emits :limited_time_offer_savings_in_cents do
      (graphql_product_hash['price_range']['minimum_price']['discount']['amount_off'] * 100).round
      regular_price_in_cents - price_in_cents
    end

    emits :limited_time_offer_ends_on do
      Date.parse(graphql_product_hash['special_to_date']).to_s rescue nil
    end

    emits :bonus_reward_miles do
      graphql_product_hash['loyalty_promo'][0]['loyalty_points'] rescue 0
    end

    emits :bonus_reward_miles_ends_on do
      Date.parse(graphql_product_hash['loyalty_promo'][0]['loyalty_enddate']).to_s rescue nil
    end

    # emits :stock_type do
    # end


    emits :origin do
      [graphql_product_hash['lcbo_region_name'], graphql_product_hash['lcbo_subregion_name']].compact.join(", ")
    end

    # emits :package do
   # end

    # emits :package_unit_type do
    #   volume_helper.unit_type
    # end

    # emits :total_package_units do
    #   volume_helper.total_units
    # end

    # emits :total_package_volume_in_milliliters do
    #   volume_helper.package_volume
    # end

    emits :volume_in_milliliters do
      graphql_product_hash['lcbo_unit_volume'].match(/(\d*)/)[1].to_i rescue nil
    end

    emits :alcohol_content do
      graphql_product_hash['lcbo_alcohol_percent'].to_f
    end

    # emits :price_per_liter_of_alcohol_in_cents do
    #   if alcohol_content > 0 && volume_in_milliliters > 0
    #     alc_frac = alcohol_content.to_f / 1000.0
    #     alc_vol  = (volume_in_milliliters.to_f / 1000.0) * alc_frac
    #     (price_in_cents.to_f / alc_vol).to_i
    #   else
    #     0
    #   end
    # end

    # emits :price_per_liter_in_cents do
    #   if volume_in_milliliters > 0
    #     (price_in_cents.to_f / (volume_in_milliliters.to_f / 1000.0)).to_i
    #   else
    #     0
    #   end
    # end

    # emits :sugar_content do
    #   if (match = find_info_line(/\ASugar Content : /))
    #     match.gsub('Sugar Content : ', '')
    #   end
    # end

    emits :producer_name do
      graphql_product_hash["lcbo_producer_name"]
    end

    emits :varietal do
      graphql_product_hash["lcbo_varietal_name"]
    end

    emits :board do
      "LCBO"
    end


    emits :released_on do
      Date.parse(graphql_product_hash['lcbo_vintage_release_date']).to_s rescue nil
    end

    # emits :is_discontinued do
    #   html.include?('PRODUCT DISCONTINUED')
    # end

    emits :has_limited_time_offer do
      sale_price_in_cents != 0
    end

    emits :has_bonus_reward_miles do
      Date.parse(bonus_reward_miles_ends_on) >= Date.today rescue false
    end

    # emits :has_value_added_promotion do
    #   html.include?('<B>Value Added Promotion</B>')
    # end

    # emits :is_seasonal do
    #   html.include?('<font color="#ff0000">SEASONAL/LIMITED QUANTITIES</font>')
    # end

    emits :is_vqa do
      graphql_product_hash["lcbo_vqa_code"] == 1
    end

    emits :is_kosher do
      graphql_product_hash["lcbo_kosher"] == 1
    end

    emits :description do
      graphql_product_hash["meta_description"]
    end

    # emits :serving_suggestion do
    #   if html.include?('<B>Serving Suggestion</B>')
    #     match = html.match(/<B>Serving Suggestion<\/B><\/font><BR>\n\t\t\t(.+?)<BR><BR>/m)
    #     CrawlKit::CaptionHelper[match && match.captures[0]]
    #   end
    # end

    # emits :tasting_note do
    #   if html.include?('<B>Tasting Note</B>')
    #     match = html.match(/<B>Tasting Note<\/B><\/font><BR>\n\t\t\t(.+?)<BR>\n\t\t\t<BR>/m)
    #     CrawlKit::CaptionHelper[match && match.captures[0]]
    #   end
    # end

    # emits :value_added_promotion_description do
    #   if has_value_added_promotion
    #     match = html.match(/<B>Value Added Promotion<\/B><\/FONT><BR>(.+?)<BR><BR>/m)
    #     CrawlKit::CaptionHelper[match && match.captures[0]]
    #   end
    # end

    # emits :image_thumb_url do
    #   if (img = doc.css('#image_holder img').first)
    #   end
    # end

    emits :label_url do
      image_url
    end

    emits :image_url do
      graphql_product_hash['image']['url']
    end

    emits :upc do
      graphql_product_hash['lcbo_upc_number']
    end

    emits :online_inventory do
      # html is updated using JS making this selector useless
      # doc.css('.home-shipping-available')[0].content.strip.match(/(\d*) available/)[1].to_i rescue 0

      # @graphql_response.to_hash['data']['getStoreProductInventory']['products'][0]['qty']
      graphql_product_hash['qty']
    end

    def graphql_product_hash
      @graphql_product_query_response.to_hash['data']['products']['items'][0]
    end


    # def volume_helper
    #   @volume_helper ||= CrawlKit::VolumeHelper.new(package)
    # end

    # def has_package?
    #   !info_cell_lines[2].include?('Price:')
    # end

    def stock_category
      cat = get_info_lines_at_offset(12).reject do |line|
        l = line.strip
        l == '' ||
        l.include?('Price:') ||
        l.include?('Bonus Reward Miles Offer') ||
        l.include?('Value Added Promotion') ||
        l.include?('Limited Time Offer') ||
        l.include?('NOTE:')
      end.first
      cat ? cat.strip : nil
    end

    def get_info_lines_at_offset(offset)
      raw_info_cell_lines.select do |line|
        match = line.scan(/\A[\s]+/)[0]
        match ? offset == match.size : false
      end
    end

    def info_cell_text
      @info_cell_text ||= info_cell_lines.join("\n")
    end

    def find_info_line(regexp)
      info_cell_lines.select { |l| l =~ regexp }.first
    end

    def raw_info_cell_lines
      @raw_info_cell_lines ||= info_cell_element.content.split(/\n/)
    end

    def info_cell_lines
      @info_cell_lines ||= begin
        raw_info_cell_lines.map { |l| l.strip }.reject { |l| l == '' }
      end
    end

    def info_cell_line_after(item)
      (i = info_cell_lines.index(item)) ? info_cell_lines[i + 1] : nil
    end

    def info_cell_html
      @info_cell_html ||= info_cell_element.inner_html
    end

    def info_cell_element
      doc.css('table[width="478"] td[height="271"] td[colspan="2"].main_font')[0]
    end


  end
end
