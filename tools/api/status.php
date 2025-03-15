<?php
$playersOnline = 0;
$data = json_decode(file_get_contents("php://input"));

//if(!$data) {
// 
//}

$requestType = $data->type;

// TOP MENU function EnterGame.postCacheInfo()

if ($requestType === 'cacheinfo') {
    if (function_exists('curl_init')) {
        try {
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, "https://otarchive.com/server/62cde2f41770eac22ec6ad19");
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_ENCODING, "");

            $site = curl_exec($ch);
            curl_close($ch);

            preg_match('/Informed Players (\d+) \(\d+\)/', $site, $matches);

            $doc = new DOMDocument();
            @$doc->loadHTML($site);

            $xpath = new DOMXPath($doc);


            $thElement = $xpath->query('//th[contains(text(), "Informed Players")]')->item(0);
            if ($thElement) {

                $tdElement = $thElement->nextSibling;
                if ($tdElement && $tdElement->nodeName === 'td') {
                    $playersOnlineText = $tdElement->nodeValue;

                    if (preg_match('/(\d+)/', $playersOnlineText, $matches)) {
                        $playersOnline = $matches[1];
                    }
                }
            }
            $playersOnline = $matches[1];
        } catch (Exception $e) {
        }
    } else {

        $site = file_get_contents("https://otarchive.com/server/62cde2f41770eac22ec6ad19");

        preg_match('/Informed Players (\d+) \(\d+\)/', $site, $matches);

        $doc = new DOMDocument();
        @$doc->loadHTML($site);

        $xpath = new DOMXPath($doc);

        $thElement = $xpath->query('//th[contains(text(), "Informed Players")]')->item(0);
        if ($thElement) {
           
            $tdElement = $thElement->nextSibling;
            if ($tdElement && $tdElement->nodeName === 'td') {
                $playersOnlineText = $tdElement->nodeValue;

                if (preg_match('/(\d+)/', $playersOnlineText, $matches)) {
                    $playersOnline = $matches[1];
                }
            }
        }
        $playersOnline = $matches[1];
    }


    $online_discord = 0;
    try {
        $online_discord = json_decode(file_get_contents("https://discordapp.com/api/guilds/628769144925585428/widget.json"))->presence_count;
    } catch (Exception $e) {
    }

    $response = array(
        "playersonline" => "$playersOnline",
        "discord_online" => $online_discord,
        "discord_link" => "https://discord.gg/tUjTBZzMCy",
        "youtube_link" => "https://www.youtube.com/watch?v=6_2zizoJKxQ",
        "gamingyoutubestreams" => "0",
        "gamingyoutubeviewer" => "0",
        "test" => $requestType,
    );
    echo json_encode($response);

    // TOP MENU function EnterGame.postEventScheduler()

} elseif ($requestType === 'eventschedule') {
    // TEST
    $eventSchedulerCalendar = array(
        array(
            "startdate" => strtotime("2024-03-20"),
            "enddate" => strtotime("2024-03-25"),
            "colorlight" => "#FF0000",
            "colordark" => "#800000",
            "description" => "Descripcion del evento 1",
            "displaypriority" => 1,
            "isseasonal" => true,
            "name" => "Evento 1",
            "specialevent" => true
        ),
        array(
            "startdate" => strtotime("2024-04-01"),
            "enddate" => strtotime("2024-04-05"),
            "colorlight" => "#00FF00",
            "colordark" => "#008000",
            "description" => "Descripcion del evento 2",
            "displaypriority" => 2,
            "isseasonal" => false,
            "name" => "Evento 2",
            "specialevent" => false
        )
    );

    $response = array(
        "lastupdatetimestamp" => time(),
        "eventlist" => $eventSchedulerCalendar,
    );
    echo json_encode($response);
}

//EnterGame.postShowOff()
elseif ($requestType === 'showoff') {

    $response = array(
        "image" => "https://raw.githubusercontent.com/mehah/otclient/main/data/images/clienticon.png",
        "title" => "OTClient - Redemption",
        "description" => "Otclient is an alternative Tibia client for usage with otserv. It aims to be complete and flexible, for that it uses LUA scripting for all game interface functionality and configurations files with a syntax similar to CSS for the client interface design."
    );
    echo json_encode($response);

    //  EnterGame.postShowCreatureBoost()
} elseif ($requestType === 'boostedcreature') {


    $response = array(
        "creature" => array(
            "type" => 222
        ),
        "boss" => array(
            "type" => 232
        )
    );
    echo json_encode($response);
} else {
    http_response_code(504);
}
?>