# frozen_string_literal: true
module Hyrax
  module Admin
    module Analytics
      class WorkReportsController < ApplicationController
        include Hyrax::SingularSubresourceController
        before_action :set_defaults
        before_action :set_document, only: [:show]
        layout 'hyrax/dashboard'

        def index
          return unless Hyrax.config.analytics == true

          @pageviews = Hyrax::Analytics.pageviews("works")
          @downloads = Hyrax::Analytics.downloads("works")
          @top_works = paginate('works', Hyrax::Analytics.top_pages("works"), rows: 10)
          @top_downloads = paginate('downloads', Hyrax::Analytics.top_downloads("works"), rows: 10)
          models = Hyrax.config.curation_concerns.map { |m| "\"#{m}\"" }
          @works_count = ActiveFedora::SolrService.query("has_model_ssim:(#{models.join(' OR ')})", fl: "id").count
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        def show
          @path = main_app.send("hyrax_#{@document._source['has_model_ssim'].first.underscore}s_path", params[:id]).sub('.', '/')
          @path = request.base_url + @path if Hyrax.config.analytics_provider == 'matomo'
          @pageviews = Hyrax::Analytics.pageviews_for_url(@path)
          @uniques = Hyrax::Analytics.unique_visitors_for_url(@path)
          @downloads = Hyrax::Analytics.downloads_for_id(@document.id)
          @files = paginate(@document._source["file_set_ids_ssim"], rows: 5)
          respond_to do |format|
            format.html
            format.csv { export_data }
          end
        end

        private

        def set_document
          @document = ::SolrDocument.find(params[:id])
        end

        def set_defaults
          @start_date = params[:start_date] || Time.zone.today - 1.month
          @end_date = params[:end_date] || Time.zone.today + 1.day
          @month_names = 12.downto(1).map { |n| DateTime::MONTHNAMES.drop(1)[(Time.zone.today.month - n) % 12] }.reverse
        end

        def export_data
          if params[:format_data] == 'downloads'
            send_data @downloads.to_csv, filename: "#{@start_date}-#{@end_date}-downloads.csv"
          elsif params[:format_data] == 'pageviews'
            send_data @pageviews.to_csv, filename: "#{@start_date}-#{@end_date}-pageviews.csv"
          elsif params[:format_data] == 'uniques'
            send_data @uniques.to_csv, filename: "#{@start_date}-#{@end_date}-uniques.csv"
          elsif params[:format_data] == 'top_works'
            send_data @top_works.map(&:to_csv).join, filename: "#{@start_date}-#{@end_date}-top_works.csv"
          elsif params[:format_data] == 'top_downloads'
            send_data @top_downloads.map(&:to_csv).join, filename: "#{@start_date}-#{@end_date}-top_downloads.csv"
          end
        end

        def paginate(data_type, results_array, rows: 2)
          return if results_array.nil?

          results_array = filter_results(data_type, results_array)
          total_pages = (results_array.size.to_f / rows.to_f).ceil
          page = request.params[:page].nil? ? 1 : request.params[:page].to_i
          current_page = page > total_pages ? total_pages : page

          Kaminari.paginate_array(results_array, total_count: results_array.size).page(current_page).per(rows)
        end

        # rubocop:disable Metrics/MethodLength
        def filter_results(data_type, results_array)
          # only return the results that currently exist

          if data_type == 'works'
            return results_array.select do |work|
              begin
                work << ::SolrDocument.find(work)
              rescue
                next
              end
            end
          end

          results_array.select do |download|
            begin
              download << FileSet.find(download)
            rescue
              next
            end
          end
        end
        # rubocop:enable Metrics/MethodLength
      end
    end
  end
end
