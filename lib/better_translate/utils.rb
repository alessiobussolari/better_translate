# frozen_string_literal: true

# lib/better_seeder/utils.rb
#
# = BetterSeeder::Utils
#
# Questo modulo fornisce metodi di utilità per la gestione dei seed. In particolare,
# consente di trasformare i nomi delle classi in formato snake_case con il suffisso "_structure.rb",
# gestire i messaggi di log e configurare il livello del logger per ActiveRecord.

module BetterTranslate
  class Utils
    class << self
      ##
      # Registra un messaggio usando il logger di Rails se disponibile, altrimenti lo stampa su standard output.
      #
      # ==== Parametri
      # * +message+ - Il messaggio da loggare (può essere una stringa o nil).
      #
      # ==== Ritorno
      # Non ritorna un valore significativo.
      #
      def logger(message: nil)
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger.info message
        else
          puts message
        end
      end
    end
  end
end
