$mots = Get-Content "mots.txt"

foreach ($mot in $mots) {

    $url = "https://www.dealabs.com/search?q=$mot"

    $response = Invoke-WebRequest -Uri $url

    $links = $response.Links | Where-Object {
        $_.outerHTML -match 'data-t="link-title"'
    }

    foreach ($link in $links) {

        $titre = $link.innerText

        foreach ($m in $mots) {

            if ($titre -match $m) {

                Write-Host "Trouve : $titre"
            }
        }
    }
}
