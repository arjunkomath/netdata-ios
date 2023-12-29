# Configuring alert notifications using Netdata Custom Agent

## Setup

### Prerequisites

- Access to the terminal where Netdata Agent is running
- Push notifications enabled on your iOS device for the app

### Configuration

1. Open the app and tap on `Settings` (top-left corner gear icon).
2. Make sure `Enable Alerts` is enabled.
3. Copy the `API Key` from the app and keep it handy.
4. Follow the instructions provided here to configure alert notifications on your Netdata Agent: https://learn.netdata.cloud/docs/alerting/notifications/agent-dispatched-notifications/custom
5. Use the following code for the `custom_sender()` method:

```bash
custom_sender() { 
    info "Start sending custom notification"
    
    title="Alarm raised for ${host}"
    body="${status_message}: ${alarm} ${raised_for}"

    curl --request POST \
      --url 'https://netdata.techulus.com/webhook/custom-alert-notification?apiKey=your_api_key' \
      --header 'Content-Type: application/json' \
      --data "{
        \"title\": \"${title}\",
        \"body\": \"${body}\"
      }"

    info "Sent custom notification"
}
``````
6. Replace `your_api_key` with the API Key copied from the app.
7. Optional: You can customize the title and body of the notification by modifying the `title` and `body` variables in the code above.
8. Test the notification using the instructions provided in test notification section: https://learn.netdata.cloud/docs/alerting/notifications/agent-dispatched-notifications/custom#test-notification


## Troubleshooting

### I'm not receiving any notifications

- Make sure you have enabled push notifications for the app on your iOS device.
- Make sure you have enabled alerts in the app.
- Make sure you have configured the custom sender correctly.
- Make sure you have configured the custom sender with the correct API Key.
