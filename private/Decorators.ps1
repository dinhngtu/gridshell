# SPDX-License-Identifier: GPL-3.0-only

function ConvertTo-OarSiteObject {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.Oar.Site" -PropertyToAdd @{
            Site = $_.uid;
        }
    }
}

function ConvertTo-OarClusterObject {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.Oar.Cluster" -PropertyToAdd @{
            Cluster = $_.uid;
            Site    = $_.links | Where-Object rel -eq "parent" | Select-Object -First 1 -ExpandProperty href | Split-Path -Leaf;
        }
    }
}

function ConvertTo-OarNodeObject {
    process {
        $parent = $_.links | Where-Object rel -eq "parent" | Select-Object -First 1 -ExpandProperty href
        $_ | Add-ObjectDetail -TypeName "G5K.Oar.Node" -PropertyToAdd @{
            Node    = $_.uid;
            Cluster = $parent | Split-Path -Leaf;
            Site    = $parent.Split("/")[3];
        }
    }
}

function ConvertTo-OarJobObject {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.Oar.Job" -PropertyToAdd @{
            JobId       = $_.uid;
            SubmittedAt = [System.DateTimeOffset]::FromUnixTimeSeconds($_.submitted_at).LocalDateTime;
            ScheduledAt = [System.DateTimeOffset]::FromUnixTimeSeconds($_.scheduled_at).LocalDateTime;
            StartedAt   = [System.DateTimeOffset]::FromUnixTimeSeconds($_.started_at).LocalDateTime;
            StoppedAt   = [System.DateTimeOffset]::FromUnixTimeSeconds($_.stopped_at).LocalDateTime;
            Duration    = [timespan]::FromSeconds($_.walltime);
            Elapsed     = [timespan]::FromSeconds([Math]::Max(0, $(if ($_.stopped_at) { $_.stopped_at } else { [System.DateTimeOffset]::Now.ToUnixTimeSeconds() }) - $_.started_at));
            Site        = $_.links | Where-Object rel -eq "parent" | Select-Object -First 1 -ExpandProperty href | Split-Path -Leaf;
        }
    }
}

function ConvertTo-KaDeployment {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.Kameleon.Deployment" -PropertyToAdd @{
            DeploymentId = $_.uid;
            CreatedAt    = [System.DateTimeOffset]::FromUnixTimeSeconds($_.created_at).LocalDateTime;
            UpdatedAt    = [System.DateTimeOffset]::FromUnixTimeSeconds($_.updated_at).LocalDateTime;
            Site         = $_.links | Where-Object rel -eq "parent" | Select-Object -First 1 -ExpandProperty href | Split-Path -Leaf;
        }
    }
}

function ConvertTo-KaEnvironment {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.Kameleon.Environment"
    }
}

function ConvertTo-G5KUser {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.User" -PropertyToAdd @{
            CreatedAt = [System.DateTimeOffset]::FromUnixTimeSeconds($_.created_at).LocalDateTime;
            UpdatedAt = [System.DateTimeOffset]::FromUnixTimeSeconds($_.updated_at).LocalDateTime;
            ExpiresAt = [System.DateTimeOffset]::FromUnixTimeSeconds($_.expires_at).LocalDateTime;
        }
    }
}

function ConvertTo-G5KGroup {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.Group"
    }
}

function ConvertTo-G5KGroupMembership {
    process {
        $_ | Add-ObjectDetail -TypeName "G5K.GroupMembership"
    }
}
