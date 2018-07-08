// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.EventHubs.Processor;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace AzureMonitor4Siem.Utils
{
    public class SimpleEventProcessor : IEventProcessor
    {
        public Task CloseAsync(PartitionContext context, CloseReason reason)
        {
            LifetimeEventsHostedService._logger.LogInformation($"Processor Shutting Down. Partition '{context.PartitionId}', Reason: '{reason}'.");
            return Task.CompletedTask;
        }

        public Task OpenAsync(PartitionContext context)
        {
            LifetimeEventsHostedService._logger.LogInformation($"SimpleEventProcessor initialized. Partition: '{context.PartitionId}'");
            return Task.CompletedTask;
        }

        public Task ProcessErrorAsync(PartitionContext context, Exception error)
        {
            LifetimeEventsHostedService._logger.LogInformation($"Error on Partition: {context.PartitionId}, Error: {error.Message}");
            return Task.CompletedTask;
        }

        public Task ProcessEventsAsync(PartitionContext context, IEnumerable<EventData> messages)
        {
            foreach (var eventData in messages)
            {
                var data = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
                LifetimeEventsHostedService._logger.LogDebug($"Message received. Partition: '{context.PartitionId}', Data: '{data}'");

                // write received data to a file whose name is the current epoch
                var fileName = (DateTime.UtcNow - new DateTime(1970, 1, 1)).TotalSeconds.ToString();
                File.WriteAllText(Path.Combine(LifetimeEventsHostedService.localLogdirectory, fileName), data);
                LifetimeEventsHostedService._logger.LogInformation("File written in " + LifetimeEventsHostedService.localLogdirectory + "/" + fileName + " at " + DateTime.Now);
            }

            return context.CheckpointAsync();
        }
    }
}