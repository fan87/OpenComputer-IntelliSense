import { workspace, ExtensionContext } from 'vscode';
import * as vscode from 'vscode';
import * as net from 'net';
import { PORT, RUN_PREFIX } from './constant';
import { constants } from 'buffer';

let client: net.Socket | null = null
let waitingForResolve: (value: vscode.CompletionItem[] | PromiseLike<vscode.CompletionItem[]>) => void = function() {}

let server: net.Server | null = null;

export function activate(context: ExtensionContext) {
	console.log("[OpenComputer IntelliSense] Initializing OpenComputer IntelliSense...")
	console.log("[OpenComputer IntelliSense] Registering Langauge Features...")
	vscode.languages.registerCompletionItemProvider("oclua", {
		provideCompletionItems(document: vscode.TextDocument, position: vscode.Position, token: vscode.CancellationToken, context: vscode.CompletionContext): vscode.ProviderResult<vscode.CompletionItem[] | vscode.CompletionList<vscode.CompletionItem>> {
			let items: vscode.CompletionItem[] = [];
			if (client == null) return { items: items };

			client.write(document.getText().substring(0, document.offsetAt(position)).replace("\n", " ").replace("\r", " ") + "\n")
			return new Promise<vscode.CompletionItem[]>((resolve, reject) => {
				waitingForResolve = resolve
			})
		}
	}, '.')
	
	console.log("[OpenComputer IntelliSense] OpenComputer IntelliSense has been enabled!")
	setupServer()

	context.subscriptions.push(vscode.commands.registerCommand("extension.opencomputer-intellisense.restartServer", () => {
		setupServer()
	}))
}

function setupServer() {
	console.log("[OpenComputer IntelliSense] Closing Server...")
	server?.close()
	console.log("[OpenComputer IntelliSense] Starting Server...")
	server = new net.Server();
	server.listen(PORT)
	server.on("connection", function(socket) {
		console.log("[OpenComputer IntelliSense] OpenComputer Client has connected!")
		vscode.window.showInformationMessage("An open computer client has connected!")
	client = socket;
		socket.on("close", () => {
			client = null;
		})
		socket.on('data', chunk => {
			let items: vscode.CompletionItem[] = [];
			for (let result of chunk.toString().split(":")) {
				if (result.startsWith("f")) {
					items.push({
						label: result.substring(1),
						kind: vscode.CompletionItemKind.Function
					})
				} else {
					items.push({
						label: result.substring(1),
						kind: vscode.CompletionItemKind.Field
					})
				}
			}
			waitingForResolve(items)
			console.log(`[OpenComputer IntelliSense] Data received from client: ${chunk.toString()}`);
		});
	})
	setInterval(() => {
		client?.write("\n")
	}, 10) // Thread system in OpenComputer is weird lol
	console.log("[OpenComputer IntelliSense] Server has started, port: " + (server.address() as net.AddressInfo).port)
	vscode.window.showInformationMessage("OpenComputer IntelliSense Integration has started! Port: " + (server.address() as net.AddressInfo).port)
}

export function deactivate() {
	console.log("[OpenComputer IntelliSense] Closing Server...")
	server?.close()
}
// rm vscode-intellisense.lua; wget http://localhost:6980/vscode-intellisense.lua; ./vscode-intellisense.lua