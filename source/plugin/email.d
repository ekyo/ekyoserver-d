/**
   Copyright: © 2013 Simon Kérouack.
   
   License: Subject to the terms of the MIT license,
   as written in the included LICENSE.txt file.
   
   Authors: Simon Kérouack
*/
module plugin.email;
import core.plugin, vibe.mail.smtp;

class EmailPlugin : Plugin {
  mixin PluginMixin;

  public {
    override void setup(Config config) {
      _settings = new SmtpClientSettings("smtp.googlemail.com", 25);
      _settings.connectionType = SmtpConnectionType.StartTLS;
      _settings.authType = SmtpAuthType.Plain;

      _settings.username = config.tryGet!string(this.name, "username");
      _settings.password = config.tryGet!string(this.name, "password");

      _logEmail = config.tryGet!string(this.name, "sendLogsTo");
      //(cast(LoggerAdapter)logger).register("Email", &log, LogLevel.Error);
    }

    void send(string to, string subject, string text) {
      auto mail = new Mail;
      mail.headers["From"] = "Server <" ~ _settings.username ~ ">";
      mail.headers["To"] = to;
      mail.headers["Subject"] = subject;
      mail.bodyText = text;

      sendMail(_settings, mail);
    }

    void log(LogData log) {
      send(_logEmail, format("%s: %s",
                            EnumValueAsString(log.level),
                            log.category), log.txt);
    }
  }

  private {
    SmtpClientSettings _settings;
    string _logEmail;
  }
}
