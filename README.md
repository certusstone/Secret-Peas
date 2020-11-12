# Project Secret Peas
This is Project Secret Peas, a proof-of-concept podcast player that also tries to verify the cryptographic signatures of the MP3 files that it plays.

### Why?
Short answer: deep fakes.

Deep fakes are synthesized audio or video clips that are nearly indistinguishable from genuine recordings. They are made by running a very large sample of genuine clips through a machine learning algorithm. With this technique, it is possible to make anyone sound like they're saying anything, given that you have a large enough sample of their voice.

Ideally, there would be no way for an attacker to insert a fake episode of your favorite podcast into the feed, but computer security is difficult and the typical podcast player has no way to tell if an audio file is a deep fake or not.

**This app also cannot tell if an audio file is a deep fake or not.**

But it can do the next best thing: verify that the file was cryptographically signed by the creator of the podcast.

Cryptograpic signatures are blocks of data that can only be created with the file they are signing and a cryptographic key. In the model this app uses, the podcast producer should have two keys, a public and private key. The public key is available for anyone to use, but the private key should never leave the producer's computer. A signature is created with the new episode and the producer's private key. This app compares the signature to the MP3 file that it receives and the public key that is associated with that producer.

The idea is that even if an attacker hacked the server hosting the podcast and inserted a deep faked episode into the feed, they wouldn't be able to sign it correctly because the necessary private key is not on the server.

### What Do Podcast Producers Need to Do?
To make this app work with your podcast, you need to generate a public and private PGP key pair, upload your public key somewhere your listeners can access it, sign the audio files that you make, and put the signature files somewhere your listeners can access it.

[Software and Resources](https://www.openpgp.org)

You can link to the signature files in the show notes of a particular episode. Adding `rel="signature"` to the anchor (`<a>`) tag that links to the file, will activate the app's autofill functionality.

### Do I Really Need to Be Worried About Deep Fakes?
No. It's not really an issue... for now.

### Then why do I need this app?
You don't. It's a mediocre podcast player (at best) and I wouldn't want to use it to listen to my podcasts. However, I believe that it's currently the best way to verify the cryptographic signatures of your podcast episodes.

Also cryptography is really cool and I would love it if more podcasts adopted these practices.

### Who built this?
[Elizabeth Berry](https://berrygood.website)

Who heavily relied on these frameworks:

[ObjectivePGP](https://objectivepgp.com)

[FeedKit](https://github.com/nmdias/FeedKit)
