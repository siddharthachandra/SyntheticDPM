categories = ['bed','chair','sofa','table']
for category in categories:
	for num in range(1,5):
		fileName = category+str(num)+'.obj'
		text = open(fileName).readlines()
		vertices = filter(lambda x:x.startswith('v '),text)
		faces = filter(lambda x:x.startswith('f '),text)
		vertices = [ v.strip()[2:] for v in vertices]
		faces = [ f.strip()[2:].split(' ') for f in faces ]
		faces = [ ' '.join([f[0].split('/')[0],f[1].split('/')[0],f[2].split('/')[0]]) for f in faces ]
		v = open(fileName+'.v','w')
		v.write('\n'.join(vertices))
		v.close()
		f = open(fileName+'.f','w')
		f.write('\n'.join(faces))
		f.close()
