


const getTokens = (line) => line.split('//')[0].split(' ').map((token) => token.trim());



//const fs = require('fs');
//const source = fs.readFileSync('./write_line.asm').toString();
document.getElementById('assemble').addEventListener('click', (e) => {
	const source = document.getElementById('editor').value;
	let lines = source.split("\n");
	
	//Find all the constants first
	let constants = {};
	lines.forEach((line, lineNumber) => {
		let tokens = getTokens(line);
		//Define is used for entrypoints and pointers
		//Set is used for constants
		if(['DEFINE', 'SET'].includes(tokens[0].toUpperCase())) {
			let varName = tokens[1];
			constants[varName] = {val: 0, refs: []};
			if(tokens[0].toUpperCase() == 'SET' && tokens[2] == '=') {
				if(tokens[3].substring(0, 1) == '"' && tokens[3].substring(-1, 1) == '"') {
					constants[varName].val = tokens[3].substring(1, -1);
				} 
				else if(tokens[3].substring(tokens[3].length-1).toLowerCase() == 'b') {
					let token = tokens[3].substring(0, tokens[3].length-1);
					if(!isNaN(parseInt(token))) {
						if(parseInt(token) >= 0) {
							constants[varName].val = parseInt(token).toString(16).padStart(2, '0');
						} else {
							constants[varName].val = (256 + parseInt(token)).toString(16);
						}
					}
				}
				else if(!isNaN(parseInt(tokens[3]))) {
					if(parseInt(tokens[3]) >= 0) {
						constants[varName].val = parseInt(tokens[3]).toString(16)
					} else {
						constants[varName].val = (65536 + parseInt(tokens[3])).toString(16);
					}
				}
			}
		}
	});

	let result = [];
	
	const parseToken = (token, offset) => {
		if(token.substring(token.length-1).toLowerCase() == 'b') {
			token = token.substring(0, token.length-1);
			if(!isNaN(parseInt(token))) {
				if(parseInt(token) >= 0) {
					return ['immediate', parseInt(token).toString(16).padStart(2, '0')];
				}
				return ['immediate', (256 + parseInt(token)).toString(16)];
			}
		}
		if(!isNaN(parseInt(token))) {
			if(parseInt(token) >= 0) {
				return ['immediate', parseInt(token).toString(16).padStart(4, '0')];
			}
			return ['immediate', (65536 + parseInt(token)).toString(16)];
		}
		else if(token.match(/^\".*\"$/)) {
			let raw = token.substring(1, token.length-1);
			return ['str', raw.split('').reduce((acc, char) => acc + char.charCodeAt(0).toString(16), '') + '00'];
		}
		else if(token.substring(0, 1) == ':') {
			constants[token]['refs'].push(result.length+offset);
			return ['ref', "0000"];
		}
	};

	const aluOps = {
		'AND': 0,
		'OR': 32,
		'XOR': 64,
		'NOT': 96,
		'ADD': 128,
		'SUB': 160,
		'MUL': 192,
		'SHIFT': 224,
	};
	const registerLookup = {
		'MEM': '1',
		'MSP': '2',
		'MIX': '3',
		'A': '4',
		'B': '5',
		'C': '6',
		'D': '7',
		'PC': '8',
		'SP': '9',
		'IDX': 'A',
		'CMP': 'B',
		'OPCODE': 'C',
		'ARG0': 'D',
		'ARG1': 'E',
		'': 'F'
	};
	const alu = (line) => {
		line = line.split('//')[0];
		//ADD PC,8 > IDX
		let command = 'B';
		let tokens = line.split(' ').slice(1).join(' ').split('>').map((token) => token.trim());
		command += registerLookup[tokens[1]];

		let alu = '';
		let op = aluOps[line.split(' ')[0].toUpperCase()];
		let quickVal = 0;
		let params = tokens[0].split(',').map((token) => token.trim());
		params.forEach((param) => {
			if(Object.keys(registerLookup).includes(param.toUpperCase())) {
				alu += registerLookup[param.toUpperCase()];
			}
			else if(parseToken(param)[0] == 'immediate') {
				alu += '0';
				quickVal = parseInt(param);
			}
		});
		result += command;
		result += alu;
		if(alu.includes('0')) {
			op += quickVal;
		}
		result += op.toString(16);

	}


	lines.forEach((line, lineNumber) => {
		let tokens = getTokens(line);
		switch(tokens[0].toUpperCase()) {
			case "MOV":
				let params = line.split('//')[0].split('>').map((token) => token.trim().replace(/^MOV /, ''))
				let command ='';
				let args = '';
				let doubleArgs = false;
				let doubleShot = false;

				params.forEach((param, index) => {
					let paramTokens = param.split('+').map((token) => token.trim());
					if(['MEM', 'MSP', 'MIX'].includes(paramTokens[0].toUpperCase()) && paramTokens.length > 1) {
						args = parseToken(paramTokens[1], 2)[1];
						command += 	registerLookup[paramTokens[0].toUpperCase()];
						doubleArgs = true;
					} 
					else if(Object.keys(registerLookup).includes(paramTokens[0].toUpperCase())) {
						command += registerLookup[paramTokens[0].toUpperCase()];
						
						if(paramTokens.length > 1) {
							doubleArgs = true;
							args = parseToken(paramTokens[1], 2)[1];
						}
					} else {
						command += '0';
						args = parseToken(paramTokens[0], 2)[1];
						if(doubleShot) {
							doubleArgs = true;
						}
						doubleShot = true;
					}
					if(!doubleArgs && doubleShot) {
						doubleArgs = ['MEM', 'MSP', 'MIX', 'PC', 'SP', 'IDX', 'C', 'D'].includes(paramTokens[0].toUpperCase());
					} else if(!doubleShot && ['MEM', 'MSP', 'MIX', 'PC', 'SP', 'IDX', 'C', 'D'].includes(paramTokens[0].toUpperCase())) {
						doubleShot = true;
					}
				});
				if(command.includes('0')) {
					command = command.replace('0', doubleArgs ? 'E' : 'D');
				}
				if(!doubleArgs) {
					args = args.substring(args.length-2);
				}
				result += command;
				result += args;
				break;

			case "DEFINE":
				let varName = tokens[1];
				constants[varName].val = (result.length/2).toString(16).padStart(4, '0');
				break;

			case "RAW":
				let raw = line.substring(4).trim();
				result += parseToken(raw, 2)[1];
				break;

			case "GOTO":
				result += 'db00'; //No cmp
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JMP":
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JE":
				result += 'db02'; //eq
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;
					
			case "JNE":
				result += 'db08'; //Not eq
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JLTE":
				result += 'db10'; //No lt or eq
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;
					
				
			case "ADD":
			case "SUB":
			case "MUL":
			case "DIV":
			case "OR":
			case "AND":
			case "NOT":
			case "XOR":
				alu(line);
				break;

			case "RETURN":
				//RETURN 8 :a
				result += '2A' + parseToken(tokens[2], 2)[1];	//Load return value into A
				result += 'A2' + (65536 - parseInt(tokens[1])+2).toString(16);	//Save return value
				result += 'B990' + (160+parseInt(tokens[1])).toString(16); // Move stack pointer to frame size
				result += 'db00';	//NP CMP on return
				result += '280000';	//Goto return address
				//MSP + 2
				break;
			default:
				
		}
	});

	Object.entries(constants).forEach(([token, constant]) => {
		constant.refs.forEach((offset) => {
			result = result.substring(0, offset) + constant.val + result.substring(offset + constant.val.length);
		});
	});

	let output = result.replaceAll(/([A-Fa-f\d]{2})/g, "$1 ");
	console.log(output);
	document.getElementById('result').value = output;
});
