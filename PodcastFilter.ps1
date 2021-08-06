$FeedAddress = "" #the podcast feed you want to filter
$FeedDirectory = ""    #Network accessible dir where your feeds will land, ideally in some sort of a webserver like \\server\nginx\www\rss so you can point your podcatcher at the address http://server/rss/[feedtitle].rss 

$GenerateEtcFeed = $true    #Generate a feed that is everything that doesn't match your filters so you don't miss announcements or poorly titled episodes
$EtcFeedTitle = "ETC"       #Title of the new feed as it should appear in filesystem as in [FeedTitle].rss
$EtcTitle = "Etc. feed for Some Podcast"     #Title of the new feed as it should appear in a podcatcher
$EtcFeedImage = "https://www.iconpacks.net/icons/1/free-microphone-icon-342-thumb.png" #the cover art for the episodes that don't fit the filters #TODO: grab this from the original RSS
$EtcDescription = "The leftovers from after the individual shows have been filtered out" #
$EtcSiteLink = ""

#grab feed data. 
$IncomingRss = Invoke-RestMethod -Uri $FeedAddress -Method Get
##also convert to Xml because in the future it would be nice to just handle this as stright xml but it's not used here
#$xml = ConvertTo-Xml $IncomingRss 


function GenerateItem { #generates an xml episode entry based on the information input to the function
    param(
        $Item
    )
    process{
        $retval = '<item><title>' + $Item.title.Replace("&","&amp;") + '</title><link>'+$Item.link+'</link><description>'+
        (ConvertTo-Xml $Item.description).InnerXml.Replace('<?xml version="1.0" encoding="utf-8"?><Objects><Object Type="System.String">','').Replace('</Object></Objects>','')+
        '</description><enclosure url="'+ ($Item.enclosure.url.Replace("&","&amp;"))+'" length="'+$Item.enclosure.length+'" type="audio/mpeg" /><guid isPermaLink="'+$Item.guid.isPermaLink+'">'+
        $Item.guid.'#text'+'</guid><pubDate>'+$Item.pubDate+'</pubDate></item>'
        return $retval
    }
}


function GenerateHeader { #generate the header for each feed. it's gross, but hey, it works
    param(
        $IncomingFeedFilter
    )
    process{
        if ($IncomingFeedFilter.ImageUrl -eq $null) {
            $IncomingFeedFilter.ImageUrl = "https://cdn.icon-icons.com/icons2/933/PNG/512/microphone-of-voice_icon-icons.com_72661.png" #this is the Material Microphone from Google
        }
        if ($IncomingFeedFilter.PodcastUrl -eq $null) {
            $IncomingFeedFilter.PodcastUrl = "https://www.google.com" #this is 
        }
        return  @'
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" xmlns:atom="http://www.w3.org/2005/Atom" xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0"><channel><title>
'@ + $IncomingFeedFilter.Title + @'  
</title><link>
'@ + $IncomingFeedFilter.PodcastUrl + @' 
</link><description>
'@ + $IncomingFeedFilter.Description + @'  
</description><atom:link href="
'@ + $IncomingFeedFilter.PodcastUrl + @' 
" rel="self" type="application/rss+xml" /><itunes:owner><itunes:name>
'@ + $IncomingFeedFilter.Title + @'  
</itunes:name><itunes:email>support@patreon.com</itunes:email></itunes:owner><itunes:author>
'@ + $IncomingFeedFilter.Title + @'  
</itunes:author><itunes:image href="
'@ + $IncomingFeedFilter.ImageUrl + @'  
" /><googleplay:block>yes</googleplay:block><itunes:block>Yes</itunes:block><language>en-US</language><pubDate>
'@ + (get-date).ToUniversalTime().ToString("ddd, d MMM yyyy hh:mm:ss") + @'
 GMT</pubDate><lastBuildDate>
'@ + (get-date).ToUniversalTime().ToString("ddd, d MMM yyyy hh:mm:ss") + @'  
 GMT</lastBuildDate><image><url>
'@ + $IncomingFeedFilter.ImageUrl + @'  
</url><title>
'@ + $IncomingFeedFilter.Title + @'  
</title><link>
'@ + $IncomingFeedFilter.PodcastUrl + @'  
</link></image>        
'@
    }

}

class FeedFilter{
    [ValidateNotNullOrEmpty()][string]$RegEx #Filter episodes based on the episode title in the feed
    [ValidateNotNullOrEmpty()][string]$Title #Title of the new feed as it should appear in a podcatcher
    [ValidateNotNullOrEmpty()][string]$Description #Description for new feed as it should appear in a podcatcher
    [ValidateNotNullOrEmpty()][string]$FeedTitle #Title of the new feed as it should appear in filesystem as in [FeedTitle].rss
    [string]$ImageUrl #Optional link to image. Note, there are some parameters that you need to follow but I don't know what they are 
    [string]$PotcastHomeSite #Optional link to the homepage of the podcast
    [Object[]]$Output #Filtered list of podcast episodes

    FeedFilter($Title, $FeedTitle, $Regex,$Description){
        $this.Title=$Title
        $this.FeedTitle=$FeedTitle
        $this.RegEx=$RegEx
        $this.Description=$Description
    }
    FeedFilter($Title, $FeedTitle, $Regex,$Description,$Image){
        $this.Title=$Title
        $this.FeedTitle=$FeedTitle
        $this.RegEx=$RegEx
        $this.Description=$Description
        $this.ImageUrl=$Image
    }
     FeedFilter($Title, $FeedTitle, $Regex,$Description,$Image,$PotcastHomeSite){
        $this.Title=$Title
        $this.FeedTitle=$FeedTitle
        $this.RegEx=$RegEx
        $this.Description=$Description
        $this.ImageUrl=$Image
        $this.PotcastHomeSite=$PotcastHomeSite
    }
}


#Specify your feeds here
$FeedFilters = New-Object Collections.Generic.List[FeedFilter] #initialize list of feed filters 
$FeedFilters += New-Object FeedFilter("Full Name of Subcast", "subcastFileName", "^[show title in every episode].*", "Show description, not super improtant, but why not include it?","[optional] https://url.toTheCover.art","[optional] https://url.toThe.Forums")
#$FeedFilters += New-Object FeedFilter(another one), etc

#if etcFeed, create here
if ($GenerateEtcFeed){ #this is the catchall to make sure your podcatcher doesn't miss a single episode, even if the episode is poorly named
    $EtcFeed = New-Object FeedFilter($EtcTitle, $EtcFeedTitle, "No Regex", $EtcDescription, $EtcFeedImage, $EtcSiteLink)
    $EtcFeed.Output = $IncomingRss
}

#Apply the filters to the incoming feed
ForEach($FeedFilter in $FeedFilters){
    $FeedFilter.Output = $IncomingRss.Where({$_.title -match $FeedFilter.RegEx})
    if ($GenerateEtcFeed){
        $EtcFeed.Output = $EtcFeed.Output.Where({$_.title -notmatch $FeedFilter.RegEx}) #apply inverted regex to etc feed so we catch all the episodes
    }
}

if ($GenerateEtcFeed){ #tack the etc feed onto the list so it can be reprocessed into rss format with the rest
    $FeedFilters += $EtcFeed
}

#Dump feeds to files
ForEach($CurrentFeedFilter in $FeedFilters){ 
     $FilePath = $FeedDirectory + $CurrentFeedFilter.FeedTitle + ".rss"
     
     #TODO: add persistance here, could be as simple as Create temp file: if tempfile.size > currentfile.size, currentfile = tempfile
     
     #not using the -Append option clears the file, 
     #generate then write the header to file
     GenerateHeader($CurrentFeedFilter)  | Out-File -FilePath $FilePath  -Encoding utf8

     #append items sequentially because xml is just a big string of text
     foreach($Item in $CurrentFeedFilter.Output){
        GenerateItem($Item) | Out-File -FilePath $FilePath -Append  -Encoding utf8
     }
     
     #put in trailing/closing tags to make sure xml is valid
     "</channel></rss>" | Out-File -FilePath $FilePath -Append  -Encoding utf8
}




