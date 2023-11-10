
/* Webhook url fr�n n�r vi l�gger till Incoming Webhook i Teams-kanalen */
%let TeamsURL=https://office365.webhook.office.com/j�ttel�ng-konstig-l�nke/87488dabc08052dd05b4d6/8c043e00-aa44-43bd-a3ff-ea76477c8b6e;

/* En enkel rad med text */
filename resp temp;
options noquotelenmax;
proc http
  /* H�r petar vi in webhook URL */
  url="&TeamsURL"
  method="POST"
  ct="text/plain"
  in=
  '{
      "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
      "type": "AdaptiveCard",
      "version": "1.0",
      "summary": "Kort meddelande fr�n SAS",
      "text": "Det h�r skickades mha PROC HTTP."
  }'
  out=resp;
run;


/* Mer komplext meddelande */
filename resp temp;
options noquotelenmax;
proc http
  /* H�r petar vi in webhook URL */
  url="&TeamsURL"
  method="POST"
  ct="text/plain"
  in=
  '{
	"@type": "MessageCard",
	"@context": "https://schema.org/extensions",
	"summary": "F�rslag p� l�t till Rock p� slottet",
	"themeColor": "0078D7",
	"title": "F�rslag p� l�t att spela",
	"sections": [
		{
			"activityTitle": "",
			"activitySubtitle": "",
			"activityImage": "https://stuff.fendergarage.com/images/G/6/Q/taxonomy-electric-guitar-stratocaster-american-professional-car@2x.png",
			"facts": [
				{
					"name": "L�t:",
					"value": "You Shook Me All Night Long"
				},
				{
					"name": "Artist:",
					"value": "AC/DC"
				},
				{
					"name": "Album:",
					"value": "Back in black"
				},
				{
					"name": "Spotify:",
					"value": "https://open.spotify.com/track/2SiXAy7TuUkycRVbbWDEpo?si=e8aa1e99a24b423e"
				},
				{
					"name": "Youtube:",
					"value": "https://youtu.be/zWCINQn6k0s?si=kP5V8MRjFTv4X2WP"
				}
			]
		}
	],
	"potentialAction": [
			{
			"@type": "OpenUri",
			"name": "�ppna Spotify",
			"targets": [
				{
					"os": "default",
					"uri": "https://open.spotify.com/track/2SiXAy7TuUkycRVbbWDEpo?si=e8aa1e99a24b423e"
				}
			]
		},
		{
			"@type": "OpenUri",
			"name": "�ppna Youtube",
			"targets": [
				{
					"os": "default",
					"uri": "https://youtu.be/zWCINQn6k0s?si=kP5V8MRjFTv4X2WP"
				}
			]
		}
	]
}'

  out=resp;
run;




