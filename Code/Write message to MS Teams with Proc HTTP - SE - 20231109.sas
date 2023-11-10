
/* Webhook url från när vi lägger till Incoming Webhook i Teams-kanalen */
%let TeamsURL=https://office365.webhook.office.com/jättelång-konstig-länke/87488dabc08052dd05b4d6/8c043e00-aa44-43bd-a3ff-ea76477c8b6e;

/* En enkel rad med text */
filename resp temp;
options noquotelenmax;
proc http
  /* Här petar vi in webhook URL */
  url="&TeamsURL"
  method="POST"
  ct="text/plain"
  in=
  '{
      "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
      "type": "AdaptiveCard",
      "version": "1.0",
      "summary": "Kort meddelande från SAS",
      "text": "Det här skickades mha PROC HTTP."
  }'
  out=resp;
run;


/* Mer komplext meddelande */
filename resp temp;
options noquotelenmax;
proc http
  /* Här petar vi in webhook URL */
  url="&TeamsURL"
  method="POST"
  ct="text/plain"
  in=
  '{
	"@type": "MessageCard",
	"@context": "https://schema.org/extensions",
	"summary": "Förslag på låt till Rock på slottet",
	"themeColor": "0078D7",
	"title": "Förslag på låt att spela",
	"sections": [
		{
			"activityTitle": "",
			"activitySubtitle": "",
			"activityImage": "https://stuff.fendergarage.com/images/G/6/Q/taxonomy-electric-guitar-stratocaster-american-professional-car@2x.png",
			"facts": [
				{
					"name": "Låt:",
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
			"name": "Öppna Spotify",
			"targets": [
				{
					"os": "default",
					"uri": "https://open.spotify.com/track/2SiXAy7TuUkycRVbbWDEpo?si=e8aa1e99a24b423e"
				}
			]
		},
		{
			"@type": "OpenUri",
			"name": "Öppna Youtube",
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




