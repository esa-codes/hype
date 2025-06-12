const { Gtk, Gdk } = imports.gi;
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, CenterBox, Entry, EventBox, Icon, Label, Overlay, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
// APIs
import GPTService from '../../services/gpt.js';
import Gemini from '../../services/gemini.js';
import { GeminiView, geminiCommands, sendMessage as geminiSendMessage, geminiTabIcon } from './apis/gemini.js';
import { ChatGPTView, chatGPTCommands, sendMessage as chatGPTSendMessage, chatGPTTabIcon } from './apis/chatgpt.js';
import { WaifuView, waifuCommands, sendMessage as waifuSendMessage, waifuTabIcon } from './apis/waifu.js';
import { BooruView, booruCommands, sendMessage as booruSendMessage, booruTabIcon } from './apis/booru.js';
import { enableClickthrough } from "../.widgetutils/clickthrough.js";
import { checkKeybind } from '../.widgetutils/keybind.js';
const TextView = Widget.subclass(Gtk.TextView, "AgsTextView");

// To store the filename and context
let attachedFileName = '';
let fileRawContext = '';

// Label to display the attached file name
const AttachedFileLabel = Label({
    className: 'txt-smallie sidebar-chat-attached-file-label',
    xalign: 0,
    truncate: 'end',
    maxWidthChars: 20, // Adjust as needed
    visible: false, // Initially hidden
});

import { widgetContent } from './sideleft.js';
import { IconTabContainer } from '../.commonwidgets/tabcontainer.js';
import { updateNestedProperty } from '../.miscutils/objects.js';

const EXPAND_INPUT_THRESHOLD = 30;
const AGS_CONFIG_FILE = `${App.configDir}/user_options.jsonc`;

export const chatEntry = TextView({
    hexpand: true,
    wrapMode: Gtk.WrapMode.WORD_CHAR,
    acceptsTab: false,
    className: 'sidebar-chat-entry txt txt-smallie',
    setup: (self) => self
        .hook(App, (self, currentName, visible) => {
            if (visible && currentName === 'sideleft') {
                self.grab_focus();
            }
        })
        .hook(GPTService, (self) => {
            if (APIS[currentApiId].name != 'Assistant (GPTs)') return;
            self.placeholderText = (GPTService.key.length > 0 ? getString('Message the model...') : getString('Enter API Key...'));
        }, 'hasKey')
        .hook(Gemini, (self) => {
            if (APIS[currentApiId].name != 'Assistant (Gemini Pro)') return;
            self.placeholderText = (Gemini.key.length > 0 ? getString('Message Gemini...') : getString('Enter Google AI API Key...'));
        }, 'hasKey')
        .on("key-press-event", (widget, event) => {
            // Don't send when Shift+Enter
            if (event.get_keyval()[1] === Gdk.KEY_Return || event.get_keyval()[1] === Gdk.KEY_KP_Enter) {
                if (event.get_state()[1] !== 17) {// SHIFT_MASK doesn't work but 17 should be shift
                    apiSendMessage(widget);
                    return true;
                }
                return false;
            }
            // Keybinds
            if (checkKeybind(event, userOptions.keybinds.sidebar.cycleTab))
                widgetContent.cycleTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.nextTab))
                widgetContent.nextTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.prevTab))
                widgetContent.prevTab();
            else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.nextTab)) {
                apiWidgets.attribute.nextTab();
                return true;
            }
            else if (checkKeybind(event, userOptions.keybinds.sidebar.apis.prevTab)) {
                apiWidgets.attribute.prevTab();
                return true;
            }
        })
    ,
});

const APILIST = {
    'gemini': {
        "name": 'Assistant (Gemini Pro)',
        "sendCommand": geminiSendMessage,
        "contentWidget": GeminiView(chatEntry),
        "commandBar": geminiCommands,
        "tabIcon": geminiTabIcon,
        "placeholderText": getString('Message Gemini...'),
    },
    'gpt': {
        "name": 'Assistant (GPTs)',
        "sendCommand": chatGPTSendMessage,
        "contentWidget": ChatGPTView(chatEntry),
        "commandBar": chatGPTCommands,
        "tabIcon": chatGPTTabIcon,
        "placeholderText": getString('Message the model...'),
    },
    'waifu': {
        "name": 'Waifus',
        "sendCommand": waifuSendMessage,
        "contentWidget": WaifuView(chatEntry),
        "commandBar": waifuCommands,
        "tabIcon": waifuTabIcon,
        "placeholderText": getString('Enter tags'),
    },
    'booru': {
        "name": 'Booru',
        "sendCommand": booruSendMessage,
        "contentWidget": BooruView(chatEntry),
        "commandBar": booruCommands,
        "tabIcon": booruTabIcon,
        "placeholderText": getString('Enter tags and/or page number'),
    },
}
const APIS = userOptions.sidebar.pages.apis.order.map((apiName) => {
    const obj = { ...APILIST[apiName] };
    obj["id"] = apiName;
    return obj;
});
let currentApiId = APIS.findIndex(obj => obj.id === userOptions.sidebar.pages.apis.defaultPage);

function apiSendMessage(textView) {
    const buffer = textView.get_buffer();
    const [start, end] = buffer.get_bounds();
    let userMessage = buffer.get_text(start, end, true).trimStart();

    // Handle clear command specifically to also clear attached file context
    if (userMessage.startsWith('/clear')) {
        fileRawContext = '';
        attachedFileName = '';
        AttachedFileLabel.label = '';
        AttachedFileLabel.visible = false;
        // The actual clearing of messages is handled by the specific API's command handler
    }

    let messageToSend = userMessage;
    if (fileRawContext) {
        // Only prepend context if the message is not a clear command that already handled it
        if (!userMessage.startsWith('/clear')) {
            messageToSend = fileRawContext + userMessage;
        }
        // For all messages (including /clear if it was attached), clear context after this send
        fileRawContext = '';
        attachedFileName = '';
        AttachedFileLabel.label = '';
        AttachedFileLabel.visible = false;
    }

    if (!messageToSend.trim() && !userMessage.startsWith('/clear')) return; // Don't send if the final message is empty, unless it's /clear

    console.log("Text being sent to AI (with hidden context if any):", messageToSend); // For debugging

    if (APIS[currentApiId].name == APILIST['booru'].name)
        APIS[currentApiId].sendCommand(messageToSend, APILIST['booru'].contentWidget);
    else
        APIS[currentApiId].sendCommand(messageToSend);

    buffer.set_text("", -1);
    chatEntryWrapper.toggleClassName('sidebar-chat-wrapper-extended', false);
    chatEntry.set_valign(Gtk.Align.CENTER);
}

chatEntry.get_buffer().connect("changed", (buffer) => {
    const bufferText = buffer.get_text(buffer.get_start_iter(), buffer.get_end_iter(), true);
    chatSendButton.toggleClassName('sidebar-chat-send-available', bufferText.length > 0);
    chatPlaceholderRevealer.revealChild = (bufferText.length == 0);
    if (buffer.get_line_count() > 1 || bufferText.length > EXPAND_INPUT_THRESHOLD) {
        chatEntryWrapper.toggleClassName('sidebar-chat-wrapper-extended', true);
        chatEntry.set_valign(Gtk.Align.FILL);
        chatPlaceholder.set_valign(Gtk.Align.FILL);
    }
    else {
        chatEntryWrapper.toggleClassName('sidebar-chat-wrapper-extended', false);
        chatEntry.set_valign(Gtk.Align.CENTER);
        chatPlaceholder.set_valign(Gtk.Align.CENTER);
    }
});

const chatEntryWrapper = Scrollable({
    className: 'sidebar-chat-wrapper',
    hscroll: 'never',
    vscroll: 'always',
    child: chatEntry,
});

const chatSendButton = Button({
    className: 'txt-norm icon-material sidebar-chat-send',
    vpack: 'end',
    label: 'arrow_upward',
    setup: setupCursorHover,
    onClicked: (self) => {
        APIS[currentApiId].sendCommand(chatEntry.get_buffer().text);
        chatEntry.get_buffer().set_text("", -1);
    },
});

const chatPlaceholder = Label({
    className: 'txt-subtext txt-smallie margin-left-5',
    hpack: 'start',
    vpack: 'center',
    label: APIS[currentApiId].placeholderText,
});

const chatPlaceholderRevealer = Revealer({
    revealChild: true,
    transition: 'crossfade',
    transitionDuration: userOptions.animations.durationLarge,
    child: chatPlaceholder,
    setup: enableClickthrough,
});

const chatAttachButton = Button({
    className: 'txt-norm icon-material sidebar-chat-send',
    vpack: 'end',
    label: 'attach_file', // Material icon for a paperclip
    setup: setupCursorHover,
    onClicked: async () => {
        try {
            const filePath = await Utils.subprocess([
                'zenity',
                '--file-selection',
                '--title=Choose a file to use as context',
            ], (path) => path.trim(), (err) => {
                console.error("File selection cancelled or failed:", err);
                return null;
            });

            if (filePath && filePath.length > 0) {
                const scriptPath = `${App.configDir}/ai/extract_doc_content.py`;
                const pythonInterpreter = GLib.get_home_dir() + '/.local/state/ags/.venv/bin/python';
                const extractedContent = await Utils.execAsync([pythonInterpreter, scriptPath, filePath]);
                const fileName = filePath.substring(filePath.lastIndexOf('/') + 1);
                
                fileRawContext = `Context from file [${fileName}]:\n${extractedContent}\n\n`;
                attachedFileName = fileName;
                AttachedFileLabel.label = `Context: ${fileName}`;
                AttachedFileLabel.visible = true;
                
                // App.sendToast(`Attached ${fileName} as context.`); // Example toast, if you have a toast system
                chatEntry.grab_focus();
            }
        } catch (error) {
            console.error("Error attaching file:", error);
            const errorMessage = error.message || "Failed to extract content from file.";
            // App.sendToast(`Error attaching file: ${errorMessage}`); // Example toast
            fileRawContext = '';
            attachedFileName = '';
            AttachedFileLabel.label = '';
            AttachedFileLabel.visible = false;
            chatEntry.grab_focus();
        }
    },
});

const textboxArea = Box({ // Entry area
    className: 'sidebar-chat-textarea',
    children: [
        Overlay({
            passThrough: true,
            child: chatEntryWrapper,
            overlays: [
                chatPlaceholderRevealer,
            ],
        }),
        Box({ className: 'width-10' }),
        chatAttachButton,
        chatSendButton,
    ]
});

// We need to add the AttachedFileLabel to the UI, for example, above the textboxArea or near the username.
// This example places it in a new Box above the textboxArea.
// You'll need to decide the best place for it in your UI structure.
// For instance, if there's a header box where the username is, that might be a good spot.
// This is a placeholder for where you might add it:
const AiTitle = () => Box({
    className: 'sidebar-chat-apititle spacing-h-5',
    hpack: 'center',
    children: [
        Label({
            hpack: 'center',
            className: 'txt-title-small sidebar-chat-apiname',
            // Bind the label to the name of the currently selected API
            // Assumes apiContentStack.shown is a Variable holding the index
            // and APIS is accessible in this scope.
            label: apiContentStack.shown.bind().as(id => APIS[id] ? APIS[id].name : ''),
        }),
        AttachedFileLabel, // Display the attached file name here
    ]
});

// You would then use AiTitle where the API title is currently displayed.
// The original code for apiContent an apiView might look something like this:
// const apiContent = Box({
//    className: 'sidebar-chat-content',
//    vertical: true,
//    children: [
//        // Original title might be here or in a header
//        APIS[currentApiId].contentWidget, // The actual chat view
//        textboxArea, // Text input area
//    ],
// });
// You'd need to integrate AiTitle() into that structure.
// For now, I'm assuming there's a place to put AiTitle.

const apiCommandStack = Stack({
    transition: 'slide_up_down',
    transitionDuration: userOptions.animations.durationLarge,
    children: APIS.reduce((acc, api) => {
        acc[api.name] = api.commandBar;
        return acc;
    }, {}),
})

export const apiContentStack = IconTabContainer({
    tabSwitcherClassName: 'sidebar-icontabswitcher',
    className: 'margin-top-5',
    iconWidgets: APIS.map((api) => api.tabIcon),
    names: APIS.map((api) => api.name),
    children: APIS.map((api) => api.contentWidget),
    initIndex: currentApiId,
    onChange: (self, id) => {
        apiCommandStack.shown = APIS[id].name;
        chatPlaceholder.label = APIS[id].placeholderText;
        currentApiId = id;
        const pageName = APIS[id].id;
        const option = 'sidebar.pages.apis.defaultPage';
        updateNestedProperty(userOptions, option, pageName);
        execAsync(['bash', '-c', `${App.configDir}/scripts/ags/agsconfigurator.py \
            --key ${option} \
            --value ${pageName} \
            --file ${AGS_CONFIG_FILE}`
        ]).catch(print);
    }

});

function switchToTab(id) {
    apiContentStack.shown.value = id;
}

const apiWidgets = Widget.Box({
    attribute: {
        'nextTab': () => switchToTab(Math.min(currentApiId + 1, APIS.length - 1)),
        'prevTab': () => switchToTab(Math.max(0, currentApiId - 1)),
    },
    vertical: true,
    className: 'spacing-v-10',
    homogeneous: false,
    children: [
        AiTitle(), // Add the title and attached file label here
        apiContentStack,
        apiCommandStack,
        textboxArea,
    ],
});

export default apiWidgets;
