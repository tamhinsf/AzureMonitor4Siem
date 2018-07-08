using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.EventHubs.Processor;
using System.IO;

namespace AzureMonitor4Siem.Utils
{
    public class LifetimeEventsHostedService : IHostedService
    {
        public static ILogger _logger;
        private readonly IApplicationLifetime _appLifetime;
        private readonly IConfiguration _configuration;   
        private static EventProcessorHost _eventProcessorHost;     

        public static string localLogdirectory;

        public LifetimeEventsHostedService(
            IConfiguration configuration, ILogger<LifetimeEventsHostedService> logger, IApplicationLifetime appLifetime)
        {
            _configuration = configuration;
            _logger = logger;
            _appLifetime = appLifetime;

            _eventProcessorHost = new EventProcessorHost(
                _configuration["az_event_hub_name"],
                PartitionReceiver.DefaultConsumerGroupName,
                _configuration["az_event_hub_connection_string"],
                _configuration["az_storage_account_connection_string"],
                _configuration["az_storage_blob_container"]);
            
            if(string.IsNullOrEmpty(_configuration["az_local_logs_dir"]))
            {
                localLogdirectory = Path.Combine(Path.GetTempPath(), Path.GetRandomFileName());
                Directory.CreateDirectory(localLogdirectory);
            }
            else
            {
                localLogdirectory = _configuration["az_local_logs_dir"];
            }
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            _appLifetime.ApplicationStarted.Register(OnStarted);
            _appLifetime.ApplicationStopping.Register(OnStopping);
            _appLifetime.ApplicationStopped.Register(OnStopped);

            return Task.CompletedTask;
        }

        public Task StopAsync(CancellationToken cancellationToken)
        {
            return Task.CompletedTask;
        }

        private void OnStarted()
        {
            _logger.LogInformation("OnStarted has been called.");
            
            // Perform post-startup activities here     
            _logger.LogInformation("Log directory is " + localLogdirectory);
            _eventProcessorHost.RegisterEventProcessorAsync<SimpleEventProcessor>();

        }

        private void OnStopping()
        {
            _logger.LogInformation("OnStopping has been called.");

            // Perform on-stopping activities here
            _eventProcessorHost.UnregisterEventProcessorAsync();
        }

        private void OnStopped()
        {
            _logger.LogInformation("OnStopped has been called.");

            // Perform post-stopped activities here
            _logger.LogInformation("Log directory is " + localLogdirectory);

        }
    }
}