module Spree
  class CartRemovalsReport < Spree::Report
    DEFAULT_SORTABLE_ATTRIBUTE = :product_name
    HEADERS                    = { options_values: :string, product_name: :string, removals: :integer, quantity_change: :integer }
    SEARCH_ATTRIBUTES          = { start_date: :product_removed_from, end_date: :product_removed_to, name: :product_name }
    SORTABLE_ATTRIBUTES        = [:product_name, :sku, :removals, :quantity_change]

    deeplink product_name: { template: %Q{<a href="/store/admin/products/{%# o.product_slug %}/variants/{%# o.variant_id %}/edit" target="_blank">{%# o.product_name %}</a>} }

    class Result < Spree::Report::Result
      class Observation < Spree::Report::Observation
        observation_fields [:product_name, :product_slug, :removals, :quantity_change, :options_values, :variant_id]
      end
    end

    def report_query
      Spree::CartEvent
        .removed
        .joins(variant: :product)
        .joins(variant: :option_values)
        .where(Spree::Product.arel_table[:name].matches(search_name))
        .where(created_at: reporting_period)
        .group('product_name', 'product_slug', 'spree_variants.sku')
        .select(
          'spree_products.name             as product_name',
          'spree_products.slug             as product_slug',
          'spree_variants.id               as variant_id',
          'spree_variants.sku              as sku',
          'count(spree_products.name)      as removals',
          "GROUP_CONCAT(DISTINCT spree_option_values.name SEPARATOR ', ') as options_values",
          'SUM(spree_cart_events.quantity) as quantity_change'
        )
    end

  end
end
