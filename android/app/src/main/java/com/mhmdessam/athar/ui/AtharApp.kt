package com.mhmdessam.athar.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.mhmdessam.athar.ui.components.AtharBottomBar
import com.mhmdessam.athar.ui.components.AtharRootTab
import com.mhmdessam.athar.ui.screens.TimelineScreen

@Composable
fun AtharApp() {
    var selectedTab by remember { mutableStateOf(AtharRootTab.Timeline) }
    var message by remember { mutableStateOf<String?>(null) }

    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        when (selectedTab) {
            AtharRootTab.Timeline -> TimelineScreen(
                onSettings = { message = "Settings comes in the next slice" },
                onScan = { message = "Scan comes in the next slice" }
            )

            AtharRootTab.Archive -> PlaceholderScreen("Archive")
        }

        AtharBottomBar(
            selected = selectedTab,
            onTimeline = {
                selectedTab = AtharRootTab.Timeline
                message = null
            },
            onScan = {
                message = "Scan comes in the next slice"
            },
            onArchive = {
                selectedTab = AtharRootTab.Archive
                message = null
            },
            modifier = Modifier.align(Alignment.BottomCenter)
        )

        message?.let { text ->
            Surface(
                modifier = Modifier
                    .align(Alignment.Center)
                    .padding(32.dp),
                shape = MaterialTheme.shapes.medium,
                tonalElevation = 3.dp
            ) {
                Text(
                    text = text,
                    modifier = Modifier.padding(20.dp),
                    color = MaterialTheme.colorScheme.onSurface
                )
            }
        }
    }
}

@Composable
private fun PlaceholderScreen(title: String) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineSmall,
            color = MaterialTheme.colorScheme.onBackground
        )
    }
}
