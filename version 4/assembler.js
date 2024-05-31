


const getTokens = (line) => line.split('//')[0].split(' ').map((token) => token.trim());

if (!Array.prototype.last){
    Array.prototype.last = function() {
        return this[this.length - 1];
    };
};

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
		if(['DEFINE', 'SET', 'CONST'].includes(tokens[0].toUpperCase())) {
			let varName = tokens[1];
			constants[varName] = {val: 0, refs: []};
			if(['SET', 'CONST'].includes(tokens[0].toUpperCase()) && tokens[2] == '=') {
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
						constants[varName].val = parseInt(tokens[3]).toString(16).padStart(4, '0');
					} else {
						constants[varName].val = (65536 + parseInt(tokens[3])).toString(16).padStart(4, 'F');
					}
				}
			}
		}
	});

	
	const parseToken = (token, offset) => {
		if(token.substring(0, 1) != ':' && token.substring(token.length-1).toLowerCase() == 'b') {
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
			raw = raw.replaceAll("\\n", "\n");
			raw = raw.replaceAll("\\0", "\0");
			raw = raw.replaceAll("\\r", "\r");
			raw = raw.replaceAll("\\t", "\t");
			return ['str', raw.split('').reduce((acc, char) => acc + char.charCodeAt(0).toString(16).padStart(2, '0'), '') + '00'];
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
		'DIV': 16,
		'REM': 48,
		"NAND": 80,
		'ADD16': 112,
		'SUB16': 144,
		'MUL16': 176,
		'DIV16': 208,
		'REM16': 240
	};
	

	const registerLookup = {
		'NUL': '0',
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
		'NUL16': 'F'
	};

	const alu = (line) => {
		line = line.split('//')[0];
		//ADD PC,8 > IDX
		let command = 'B';
		let tokens = line.split(' ').slice(1).join(' ').split('>').map((token) => token.trim());
		command += registerLookup[tokens[1]];

		let alu = '';
		let op = aluOps[line.split(' ')[0].trim().toUpperCase()];
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
		result += op.toString(16).padStart(2, '0');

	}


	
	let result = [];
	let currFunc = [];
	let frameSize = 0;

	lines.forEach((line, lineNumber) => {
		let params = [];
		let tokens = getTokens(line);
		switch(tokens[0].toUpperCase()) {
			case "MOV":
				params = line.split('//')[0].split('>').map((token) => token.trim().replace(/^MOV /, ''))
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
						command += '?';
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
				if(command.includes('?')) {
					command = command.replace('?', doubleArgs ? 'E' : 'D');
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
				let raw = line.substring(4).split("//")[0].trim();
				result += parseToken(raw, 0)[1];
				break;

			case "GOTO":
				result += 'db00'; //No cmp
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JMP":
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JE":
				result += 'db01'; //eq
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;
					
			case "JNE":
				result += 'db08'; //Not eq
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JLTE":
				result += 'db10'; //less than or equal to
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JGT":
				result += 'db02'; //greater than
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;

			case "JLT":
				result += 'db04'; //less than
				result += 'e8' + parseToken(tokens[1], 2)[1];
				break;
					
				
			case "ADD":
			case "SUB":
			case "MUL":
			case "DIV":
			case "REM":
			case "OR":
			case "AND":
			case "NOT":
			case "XOR":
			case "SHIFT":
			case "ADD16":
			case "SUB16":
			case "MUL16":
			case "DIV16":
			case "REM16":
				alu(line);
				break;

			
			case "CALL":
				let func = line.match(/CALL\s{1,3}(?<name>:[\da-z_A-Z]+)\((?<args>[:\da-z_&A-Z\s,]*)\)/i);
				
				frameSize = Object.values(constants[func.groups['name'].trim()]['offsets']).length * 2;
				params = Object.values(constants[func.groups['name'].trim()]['offsets']).filter((offset) => offset.type=='param');
				if(func.groups['args'].length > 0) {
					func.groups['args'].split(',').map((arg) => arg.trim()).forEach((arg, index) => {
						if(arg.substring(0, 1) == ':') {
							if(currFunc.length > 0 && typeof(constants[currFunc.last()].offsets) !== 'undefined' && Object.keys(constants[currFunc.last()].offsets).includes(arg)) {
								result += '2A' + parseToken(arg, 2)[1];
							} else {
								result += '1A' + parseToken(arg, 2)[1];
							}
						} else if(arg.substring(0, 1) == '&') {
							result += 'EA' + parseToken(arg.replace('&', ':'), 2)[1];
						} else {
							result += 'EA' + parseToken(arg, 2)[1];
						}
						result += 'A2' + (frameSize+params[index].val).toString(16).padStart(4, '0');
					});
				}

				//result += 'EA' + frameSize.toString(16).padStart(4, '0');
				result += 'BA8088';	//Add IDX to PC into IDX;
				result += 'A20000';
				result += 'db00'; //Clear conditional flags
				result += 'E8' + parseToken(func.groups['name'].trim(), 2)[1];
				//MOV 5 > D
				//MOV D > MSP + 4 //Set d as param for next call
				//ADD PC,8 > IDX	
				//MOV IDX > MSP + 0 //Add return address
				break;

			case "FUNC":
				let offsets = {};
				let funcName = line.match(/FUNC (:[\da-z_A-Z]+)/i)[1];

				let locals = line.match(/LOCAL\(([:\da-z_A-Z\s,]*)\)/i);
				if(locals.length > 1 && locals[1] !== '') {
					locals[1].split(',').forEach((localVar) => {
						constants[localVar.trim()] = {
							val: (Object.values(offsets).length+1)*-2,
							refs: [],
							bounds: [result.length, result.length+4],
							type: 'local'
						};
						offsets[localVar.trim()] = constants[localVar.trim()];
					});
				}
				
				let paramList = line.match(/PARAM\(([:\da-z_A-Z\s,]*)\)/i);
				if(paramList.length > 1 && paramList[1] !== '') {
					paramList[1].split(',').forEach((param) => {
						constants[param.trim()] = {
							val: (Object.values(offsets).length+1)*-2,
							refs: [],
							bounds: [result.length, result.length+4],
							type: 'param'
						};
						offsets[param.trim()] = constants[param.trim()];
					});
				}

				let returnName = line.match(/RETURN\((:[\da-z_A-Z]+)\)/i)[1];
				offsets[returnName.trim()] = {
					val: (Object.values(offsets).length+1) * -2,
					refs: [],
					bounds: [result.length, result.length+4],
					type: 'returnVal'
				};

				offsets[':return_address'] = {
					val: (Object.values(offsets).length+1) * -2,
					refs: [],
					bounds: [result.length, result.length+4],
					type: 'returnAddr'
				}
				
				constants[funcName] = {
					refs: [],
					val: (result.length/2).toString(16).padStart(4, '0'),
					'offsets': offsets
				};
				currFunc.push(funcName);

				frameSize = Object.values(offsets).length * 2;
				//ADD SP,8 > SP
				if(frameSize <= 14) {
					result += 'B990' + (128+parseInt(frameSize)).toString(16); // Move stack pointer to frame size
				} else {
					result += 'E6' + parseInt(frameSize).toString(16).padStart(4, '0');//MOV $frameSize > C
					result += 'B99680';	//Add C onto SP	
				}

				break;


			case "RETURN":
				//RETURN :a
				//RETURN 8
				//RETURN
				if(currFunc.length > 0 && typeof(constants[currFunc.last()]) !== 'undefined') {
					frameSize = Object.values(constants[currFunc.last()]['offsets']).length * 2;
					if(tokens.length > 1) {
						//Move return value
						if(tokens[1].substring(0, 1) == ':') {
							let offset = constants[currFunc.last()]['offsets'][tokens[1]].val;
							result += '2A' + (65536 + offset).toString(16);	//Load return value into IDX
						} else {
							result += 'EA' + parseToken(tokens[1], 2)[1];	//Load return value into IDX
						}
						result += 'A2' + (65536 - parseInt(frameSize)+2).toString(16);	//Save return value
					}

					if(frameSize <= 14) {
						result += 'B990' + (160+parseInt(frameSize)).toString(16); // Move stack pointer to frame size
					} else {
						result += 'E6' + parseInt(frameSize).toString(16).padStart(4, '0');//MOV $frameSize > C
						result += 'B996A0';	//Sub C from SP	
					}
					result += 'db00';	//NP CMP on return
					result += '280000';	//Goto return address

					//Set upper bound of function vars scope
					Object.values(constants[currFunc.last()]['offsets']).forEach((offset) => offset['bounds'][1] = result.length);
					currFunc.pop();
				}
				
				//MSP + 2
				break;
			default:	
				break;
		}
	});

	Object.entries(constants).forEach(([token, constant]) => {
		constant.refs.forEach((offset) => {
			if(Object.keys(constant).includes('bounds')) {
				if(offset > constant['bounds'][0] && offset < constant['bounds'][0]) {
					return;	//Do not map a constant outside of function scope
				}
			}
			let substitute = constant.val;
			if(typeof(constant.val) === 'number') {
				if(constant.val >= 0) {
					substitute = parseInt(constant.val).toString(16).padStart(4, '0');
				} else {
					substitute = (65536 + parseInt(constant.val)).toString(16).padStart(4, 'F');
				}
			}
			result = result.substring(0, offset) + substitute + result.substring(offset + substitute.length);
		});
	});

	let output = result.replaceAll(/([A-Fa-f\d]{2})/g, "$1 ");
	console.log(output);
	document.getElementById('result').value = output;
});
